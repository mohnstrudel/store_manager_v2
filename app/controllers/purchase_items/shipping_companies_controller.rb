# frozen_string_literal: true

module PurchaseItems
  class ShippingCompaniesController < ApplicationController
    include PurchaseItemScoped

    def show
      render partial: "purchase_items/inline_shipping_company_show", locals: {purchase_item: @purchase_item}
    end

    def edit
      render partial: "purchase_items/inline_shipping_company_edit", locals: {purchase_item: @purchase_item}
    end

    def update
      if @purchase_item.update(shipping_company_id: params[:purchase_item][:shipping_company_id])
        redirect_to purchase_item_path(@purchase_item), notice: "Shipping company was successfully updated"
      else
        render partial: "purchase_items/inline_shipping_company_edit",
          locals: {purchase_item: @purchase_item},
          status: :unprocessable_content
      end
    end

    private

    def authorize_resourse
      if action_name == "update"
        authorize :purchase_item, :update_shipping_company?
      else
        authorize :purchase_item, :edit_shipping_company?
      end
    end
  end
end
