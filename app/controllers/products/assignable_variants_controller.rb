# frozen_string_literal: true

module Products
  class AssignableVariantsController < ApplicationController
    def show
      render json: VariantAvailabilityResource.new(@product).serializable_hash
    end

    private

    def authorize_resource
      @product = policy_scope(Product).find(params.expect(:product_id))
      authorize @product, :show?
    end
  end
end
