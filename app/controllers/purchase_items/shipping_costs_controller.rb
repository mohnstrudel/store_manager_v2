# frozen_string_literal: true

module PurchaseItems
  class ShippingCostsController < ApplicationController
    include ReturnPath
    include PurchaseItemScoped

    def update
      if @purchase_item.update(shipping_cost: purchase_item_params[:shipping_cost])
        redirect_to return_path, notice: "Shipping cost was successfully updated"
      else
        redirect_to return_path, inertia: inertia_errors(@purchase_item.errors)
      end
    end

    private

    def purchase_item_params
      params.expect(purchase_item: [:shipping_cost])
    end

    def default_return_path
      purchase_item_path(@purchase_item)
    end

    def authorize_resource
      authorize :purchase_item, :update_shipping_cost?
    end
  end
end
