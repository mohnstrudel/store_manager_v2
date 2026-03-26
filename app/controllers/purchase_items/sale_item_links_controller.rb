# frozen_string_literal: true

module PurchaseItems
  class SaleItemLinksController < ApplicationController
    include PurchaseItemScoped

    def destroy
      sale_item = @purchase_item.sale_item
      target_path = sale_item_path(sale_item.sale, sale_item) if sale_item

      if @purchase_item.update(sale_item: nil)
        redirect_to (request.referer || target_path),
          notice: "Purchase item was successfully unlinked",
          status: :see_other
      else
        redirect_to target_path,
          alert: "Something went wrong. Try again later or contact the administrators",
          status: :see_other,
          turbolinks: false
      end
    end

    private

    def authorize_resourse
      authorize :purchase_item, :unlink?
    end
  end
end
