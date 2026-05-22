# frozen_string_literal: true

module Sales
  class ItemsController < ApplicationController
    before_action :set_sale
    before_action :set_sale_item, only: %i[show destroy]

    def show
      render inertia: "SaleItems/Show", props: {
        sale_item: sale_item_props(@sale_item),
        purchase_items: @sale_item.purchase_items.map { |purchase_item| purchase_item_props(purchase_item) },
        warehouses: Warehouse.order(name: :asc).map { |warehouse| {id: warehouse.id, name: warehouse.name.to_s} },
        warehouse_move_path: warehouse_move_path
      }
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

    def sale_item_props(sale_item)
      {
        id: sale_item.id,
        title: helpers.format_show_page_title(sale_item).to_s,
        qty: sale_item.qty.to_i,
        price: helpers.format_money(sale_item.price).to_s,
        product_path: product_path(sale_item.product),
        sale_path: sale_path(sale_item.sale)
      }
    end

    def purchase_item_props(purchase_item)
      {
        id: purchase_item.id,
        path: purchase_item_path(purchase_item),
        edit_path: edit_purchase_item_path(purchase_item, redirect_to_sale_item: true),
        unlink_path: purchase_item_sale_item_link_path(purchase_item),
        warehouse_name: purchase_item.warehouse.name.to_s,
        size: helpers.format_item_size(purchase_item).to_s,
        weight: purchase_item.weight.to_s,
        expenses: helpers.format_money(purchase_item.expenses).to_s,
        shipping_cost: helpers.format_money(purchase_item.shipping_cost).to_s
      }
    end
  end
end
