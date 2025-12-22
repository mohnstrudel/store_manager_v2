# frozen_string_literal: true
class Shopify::UpdateProductJob < ApplicationJob
  def perform(product_id)
    product = Product.find(product_id)
    serialized_product = Shopify::ProductSerializer.serialize(product)

    if serialized_product.present?
      api_client = Shopify::ApiClient.new

      product_shopify_info = product.store_infos.find_or_initialize_by(store_name: :shopify)

      return if product_shopify_info.store_id.blank?

      product_response = api_client.product_update(product_shopify_info.store_id, serialized_product)

      product_shopify_info.assign_attributes(
        push_time: Time.current,
        slug: product_response["handle"]
      )
      product_shopify_info.save!

      if product.images.any?
        Shopify::AddImageJob.perform_later(product_shopify_info.store_id, product.id)
      end

      if product.sizes.any? || product.versions.any? || product.colors.any?
        Shopify::CreateOptionsAndVariantsJob.perform_later(product.id, product_shopify_info.store_id)
      end

      true
    end
  end
end
