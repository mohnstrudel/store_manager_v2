# frozen_string_literal: true

module PurchaseItems
  class TrackingNumbersController < ApplicationController
    include PurchaseItemScoped

    def show
      render turbo_stream: turbo_replace_purchase_item(:tracking_number, "inline_tracking_show")
    end

    def edit
      if @purchase_item.shipping_company_id.present?
        render turbo_stream: turbo_replace_purchase_item(:tracking_number, "inline_tracking_edit")
      else
        render turbo_stream: [
          turbo_replace_purchase_item(:tracking_number, "inline_tracking_edit"),
          turbo_replace_purchase_item(:shipping_company, "inline_shipping_company_edit")
        ]
      end
    end

    def update
      if @purchase_item.update(tracking_number: params[:purchase_item][:tracking_number])
        render turbo_stream: turbo_replace_purchase_item(:tracking_number, "inline_tracking_show")
      else
        render turbo_stream: turbo_replace_purchase_item(:tracking_number, "inline_tracking_edit")
      end
    end

    private

    def authorize_resourse
      if action_name == "update"
        authorize :purchase_item, :update_tracking_number?
      else
        authorize :purchase_item, :edit_tracking_number?
      end
    end
  end
end
