# frozen_string_literal: true

module Purchases
  class ProductVariantsController < ApplicationController
    def show
      product = Product.find(params.expect(:product_id))
      variants = product.fetch_variants_with_title

      render json: {
        variants: variants.map { |variant| {value: variant.id, label: variant.title.to_s} }
      }
    end

    private

    def authorize_resource
      authorize :purchase, :product_variants?
    end
  end
end
