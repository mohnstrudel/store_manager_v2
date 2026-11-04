# frozen_string_literal: true

module Products
  class ShopifyPushesController < ApplicationController
    include ProductScoped

    def create
      @product.push_to_shopify_later

      redirect_back_or_to product_path(@product), notice: notice_message
    end

    private

    def notice_message
      "Product is being pushed to Shopify"
    end

    def authorize_resource
      authorize :product, :push_to_shopify?
    end
  end
end
