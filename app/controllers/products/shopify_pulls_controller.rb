# frozen_string_literal: true

module Products
  class ShopifyPullsController < ApplicationController
    include ProductScoped

    def create
      notice = if @product.shopify_info&.store_id&.present?
        Shopify::PullProductJob.perform_later(@product.shopify_info.store_id)
        "Product is being fetched from Shopify"
      else
        "Product has not been published to Shopify yet"
      end

      redirect_back_or_to product_path(@product), notice:
    end

    private

    def authorize_resourse
      authorize :product, :pull_from_shopify?
    end
  end
end
