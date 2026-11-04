# frozen_string_literal: true

module Product::Shopify::Pushable
  extend ActiveSupport::Concern

  class_methods do
    def forget_shopify_listing(store_id)
      listing = StoreInfo.find_by(store_name: "shopify", store_id:)

      return unless listing

      listing.storable.forget_shopify_listing(listing)
    end
  end

  def push_to_shopify_later
    if shopify_linked?
      ::Shopify::UpdateProductJob.perform_later(id)
    else
      ::Shopify::CreateProductJob.perform_later(id)
    end
  end

  def create_in_shopify_now
    serialized_product = shopify_payload

    return if serialized_product.blank?

    product_response = ::Shopify::Api::Client.new.create_product(serialized_product)
    product_store_id = product_response.fetch("id")

    upsert_shopify_info(
      store_id: product_store_id,
      slug: product_response.fetch("handle"),
      push_time: Time.current
    )

    push_shopify_media_and_options_later(product_store_id)

    true
  end

  def update_in_shopify_now
    client = ::Shopify::Api::Client.new
    listing = shopify_info

    product_payload = client.update_product(listing.store_id, shopify_payload)

    listing.assign_attributes(
      push_time: Time.current,
      slug: product_payload["handle"]
    )
    listing.save!

    remove_outdated_shopify_media(product_payload)
    push_shopify_media_and_options_later(listing.store_id)

    true
  rescue ::Shopify::Api::Client::ApiError => e
    raise unless e.message.include?("Product does not exist")

    forget_shopify_listing
  end

  def forget_shopify_listing(listing = shopify_info)
    return unless listing

    StoreInfo
      .where(
        store_name: "shopify",
        storable_type: "Media",
        storable_id: media.select(:id)
      )
      .delete_all

    listing.destroy!
  end

  private

  def push_shopify_media_and_options_later(product_store_id)
    if media.any?
      ::Shopify::PushMediaJob.perform_later(id, product_store_id)
    end

    if sizes.any? || versions.any? || colors.any?
      ::Shopify::CreateOptionsAndVariantsJob.perform_later(id, product_store_id)
    end
  end

  def remove_outdated_shopify_media(product_payload)
    shopify_media_ids = product_payload.dig("media", "nodes")&.pluck("id") || []

    StoreInfo
      .where(
        storable_type: "Media",
        storable_id: media.select(:id),
        store_name: "shopify"
      )
      .where.not(store_id: shopify_media_ids)
      .delete_all
  end
end
