# frozen_string_literal: true

module PurchaseItems
  class ShippingCompaniesController < ApplicationController
    include PurchaseItemScoped

    def update
      if @purchase_item.update(shipping_company_id: params[:purchase_item][:shipping_company_id])
        redirect_to return_path, notice: "Shipping company was successfully updated"
      else
        redirect_to return_path, inertia: inertia_errors(@purchase_item.errors)
      end
    end

    private

    def authorize_resourse
      authorize :purchase_item, :update_shipping_company?
    end

    def return_path
      params[:return_to].presence || purchase_item_path(@purchase_item)
    end
  end
end
