# frozen_string_literal: true

module Sales
  class ItemsController < ApplicationController
    before_action :set_sale
    before_action :set_sale_item, only: %i[show destroy]

    def show
      render "sale_items/show"
    end

    def destroy
      unlink_purchase_items
      @sale_item.destroy!
      redirect_to redirect_path,
        notice: "Sale item was successfully destroyed",
        status: :see_other
    end

    private

    def authorize_resourse
      authorize :sale_item
    end

    def set_sale
      @sale = Sale.friendly.find(params[:sale_id])
    end

    def set_sale_item
      @sale_item = sale_items_scope.find(params[:id])
    end

    def sale_items_scope
      if action_name == "show"
        @sale.sale_items.for_details
      else
        @sale.sale_items
      end
    end

    def unlink_purchase_items
      @sale_item.purchase_items.find_each { |purchase_item| purchase_item.update!(sale_item_id: nil) }
    end

    def redirect_path
      params[:return_to].presence || sale_path(@sale)
    end
  end
end
