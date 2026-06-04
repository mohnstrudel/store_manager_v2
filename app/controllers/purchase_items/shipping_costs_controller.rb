# frozen_string_literal: true

module PurchaseItems
  class ShippingCostsController < ApplicationController
    include PurchaseItemScoped

    def update
      if @purchase_item.update(shipping_cost: params[:purchase_item][:shipping_cost])
        redirect_to return_path, notice: "Shipping cost was successfully updated"
      else
        redirect_to return_path, inertia: inertia_errors(@purchase_item.errors)
      end
    end

    private

    def authorize_resource
      authorize :purchase_item, :update_shipping_cost?
    end

    def return_path
      params[:return_to].presence || purchase_item_path(@purchase_item)
    end
  end
end
