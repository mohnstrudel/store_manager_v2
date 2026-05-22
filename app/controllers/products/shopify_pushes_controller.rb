# frozen_string_literal: true

module Products
  class ShopifyPushesController < ApplicationController
    include ProductScoped

    def create
      enqueue_push_job

      redirect_back_or_to product_path(@product), notice: notice_message
    end

    private

    def enqueue_push_job
      if @product.shopify_linked?
        Shopify::UpdateProductJob.perform_later(@product.id)
      else
        Shopify::CreateProductJob.perform_later(@product.id)
      end
    end

    def notice_message
      "Product is being pushed to Shopify"
    end

    def authorize_resourse
      authorize :product, :push_to_shopify?
    end
  end
end
