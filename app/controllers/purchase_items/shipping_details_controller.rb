# frozen_string_literal: true

module PurchaseItems
  class ShippingDetailsController < ApplicationController
    include PurchaseItemScoped

    def update
      if @purchase_item.update(permitted_params)
        redirect_to return_path, notice: "Shipping details were successfully updated"
      else
        redirect_to return_path, inertia: inertia_errors(@purchase_item.errors)
      end
    end

    private

    def authorize_resource
      authorize :purchase_item, :update_shipping_details?
    end

    def permitted_params
      params.require(:purchase_item).permit(:tracking_number, :shipping_company_id, :shipping_cost)
    end

    def return_path
      params[:return_to].presence || purchase_item_path(@purchase_item)
    end
  end
end
