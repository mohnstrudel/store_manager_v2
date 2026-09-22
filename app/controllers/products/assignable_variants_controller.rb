# frozen_string_literal: true

module Products
  class AssignableVariantsController < ApplicationController
    def show
      render json: helpers.variant_availability_props(@product)
    end

    private

    def authorize_resource
      @product = policy_scope(Product).find(params.expect(:product_id))
      authorize @product, :show?
    end
  end
end
