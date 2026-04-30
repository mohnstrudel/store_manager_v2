# frozen_string_literal: true

module Purchases
  class ProductVariantsController < ApplicationController
    def show
      @target = params[:target]
      @product = Product.find(params[:product_id])
      @variants = @product.fetch_variants_with_title

      respond_to do |format|
        format.turbo_stream { render "purchases/product_variants" }
      end
    end

    private

    def authorize_resourse
      authorize :purchase, :product_variants?
    end
  end
end
