# frozen_string_literal: true

module Purchases
  class ProductEditionsController < ApplicationController
    def show
      @target = params[:target]
      @product = Product.find(params[:product_id])
      @editions = @product.fetch_editions_with_title

      respond_to do |format|
        format.turbo_stream { render "purchases/product_editions" }
      end
    end

    private

    def authorize_resourse
      authorize :purchase, :product_editions?
    end
  end
end
