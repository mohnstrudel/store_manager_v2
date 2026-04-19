# frozen_string_literal: true

module Shopify
  class CreateProductJob < ApplicationJob
    def perform(product_id)
      product = Product.find(product_id)
      serialized_product = product.shopify_payload

      if serialized_product.present?
        client = Shopify::Api::Client.new

        product_response = client.create_product(serialized_product)
        product_store_id = product_response.fetch("id")
        product_slug = product_response.fetch("handle")

        product.link_shopify_info!(
          store_id: product_store_id,
          slug: product_slug
        )
        product.mark_shopify_pushed!

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
