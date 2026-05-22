# frozen_string_literal: true

module PurchaseItems
  class TrackingNumbersController < ApplicationController
    include PurchaseItemScoped

    def show
      render partial: "purchase_items/inline_tracking_show", locals: {purchase_item: @purchase_item}
    end

    def edit
      render partial: "purchase_items/inline_tracking_edit", locals: {purchase_item: @purchase_item}
    end

    def update
      if @purchase_item.update(tracking_number: params[:purchase_item][:tracking_number])
        redirect_to purchase_item_path(@purchase_item), notice: "Tracking number was successfully updated"
      else
        render partial: "purchase_items/inline_tracking_edit",
          locals: {purchase_item: @purchase_item},
          status: :unprocessable_content
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
