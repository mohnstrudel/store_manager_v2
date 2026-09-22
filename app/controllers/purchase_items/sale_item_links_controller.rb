# frozen_string_literal: true

module PurchaseItems
  class SaleItemLinksController < ApplicationController
    include PurchaseItemScoped

    def create
      target = SaleItem.find(params.expect(:sale_item_id))
      unlink_purchase_items =
        if (purchase_item_id = params[:purchase_item_to_unlink_id])
          [target.purchase_items.find(purchase_item_id)]
        else
          []
        end

      PurchaseItem.link_exact!(
        assignments: [{purchase_item: @purchase_item, sale_item: target}],
        unlink_purchase_items:
      )

      redirect_to edit_purchase_item_path(@purchase_item),
        notice: "Sale item linked successfully.",
        status: :see_other
    end

    def destroy
      sale_item = @purchase_item.sale_item
      target_path = sale_item_path(sale_item.sale, sale_item) if sale_item

      if @purchase_item.unlink_from_sale_item!
        redirect_to (request.referer || target_path),
          notice: "Purchase item was successfully unlinked",
          status: :see_other
      else
        redirect_to target_path,
          alert: "Something went wrong. Try again later or contact the administrators",
          status: :see_other
      end
    end

    private

    def authorize_resource
      authorize :purchase_item, :unlink?
    end
  end
end
