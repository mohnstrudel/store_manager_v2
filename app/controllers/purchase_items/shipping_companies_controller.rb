# frozen_string_literal: true

module PurchaseItems
  class ShippingCompaniesController < ApplicationController
    include PurchaseItemScoped

    def show
      render turbo_stream: turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_show")
    end

    def edit
      render turbo_stream: turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_edit")
    end

    def update
      if @purchase_item.update(shipping_company_id: params[:purchase_item][:shipping_company_id])
        render turbo_stream: turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_show")
      else
        render turbo_stream: turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_edit")
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
