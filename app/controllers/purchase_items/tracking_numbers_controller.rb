# frozen_string_literal: true

module PurchaseItems
  class TrackingNumbersController < ApplicationController
    include ReturnPath
    include PurchaseItemScoped

    def update
      if @purchase_item.update(tracking_number: purchase_item_params[:tracking_number])
        redirect_to return_path, notice: "Tracking number was successfully updated"
      else
        redirect_to return_path, inertia: inertia_errors(@purchase_item.errors)
      end
    end

    private

    def purchase_item_params
      params.expect(purchase_item: [:tracking_number])
    end

    def default_return_path
      purchase_item_path(@purchase_item)
    end

    def authorize_resource
      authorize :purchase_item, :update_tracking_number?
    end
  end
end
