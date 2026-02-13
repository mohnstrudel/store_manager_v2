# frozen_string_literal: true

module Shopify
  class CreateProductJob < ApplicationJob
    def perform(product_id)
      product = Product.find(product_id)
      serialized_product = Product::ShopifySerializer.for_export(product)

      if serialized_product.present?
        client = Shopify::Api::Client.new

        product_shopify_info = product.store_infos.find_or_initialize_by(store_name: :shopify)

        product_response = client.create_product(serialized_product)
        product_store_id = product_response["id"]

        product_shopify_info.assign_attributes(
          push_time: Time.current,
          store_id: product_store_id,
          slug: product_response["handle"]
        )
        product_shopify_info.save!

        if product.media.any?
          Shopify::PushMediaJob.perform_later(product.id, product_store_id)
        end

        if product.sizes.any? || product.versions.any? || product.colors.any?
          Shopify::CreateOptionsAndVariantsJob.perform_later(product.id, product_store_id)
        end

        true
      end
    end
  end
end
