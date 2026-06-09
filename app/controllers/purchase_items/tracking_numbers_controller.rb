# frozen_string_literal: true

module PurchaseItems
  class TrackingNumbersController < ApplicationController
    include PurchaseItemScoped

    def update
      if @purchase_item.update(tracking_number: params[:purchase_item][:tracking_number])
        redirect_to return_path, notice: "Tracking number was successfully updated"
      else
        redirect_to return_path, inertia: inertia_errors(@purchase_item.errors)
      end
    end

    private

    def authorize_resource
      authorize :purchase_item, :update_tracking_number?
    end

    def return_path
      params[:return_to].presence || purchase_item_path(@purchase_item)
    end
  end
end
