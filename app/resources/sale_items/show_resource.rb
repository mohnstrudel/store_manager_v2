# frozen_string_literal: true

class SaleItems::ShowResource < ApplicationResource
  typelize({id: :number, title: "string | null", qty: :number, price: "string | null", product_path: :string, sale_path: :string})
  attribute :sale_item do |page|
    sale_item = page.fetch(:sale_item)

    {
      id: sale_item.id,
      title: format_show_page_title(sale_item),
      qty: sale_item.qty.to_i,
      price: format_money(sale_item.price),
      product_path: product_path(sale_item.product),
      sale_path: sale_path(sale_item.sale)
    }
  end

  typelize "Array<SaleItemsPurchaseItem>"
  attribute :purchase_items do |page|
    SaleItems::PurchaseItemResource.new(page.fetch(:sale_item).purchase_items).serializable_hash
  end

  typelize "Array<WarehouseOption>"
  attribute :warehouses do |_page|
    WarehouseOptionResource.new(Warehouse.order(name: :asc)).serializable_hash
  end

  typelize :string
  attribute :warehouse_move_path do |_page|
    warehouse_move_path
  end
end
