# frozen_string_literal: true

module PurchaseItems
  class ShippingCompaniesController < ApplicationController
    include ReturnPath
    include PurchaseItemScoped

    def update
      if @purchase_item.update(shipping_company_id: purchase_item_params[:shipping_company_id])
        redirect_to return_path, notice: "Shipping company was successfully updated"
      else
        redirect_to return_path, inertia: inertia_errors(@purchase_item.errors)
      end
    end

    private

    def purchase_item_params
      params.expect(purchase_item: [:shipping_company_id])
    end

    def default_return_path
      purchase_item_path(@purchase_item)
    end

    def authorize_resource
      authorize :purchase_item, :update_shipping_company?
    end
  end
end
