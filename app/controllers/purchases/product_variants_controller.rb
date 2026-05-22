# frozen_string_literal: true

module Purchases
  class ProductVariantsController < ApplicationController
    def show
      product = Product.find(params[:product_id])
      variants = product.fetch_variants_with_title

      render json: {
        variants: variants.map { |variant| {id: variant.id, title: variant.title.to_s} }
      }
    end

    private

    def authorize_resourse
      authorize :purchase, :product_variants?
    end
  end
end
