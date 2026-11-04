# frozen_string_literal: true

class Sales::DetailPurchaseItemResource < ApplicationResource
  typelize_from PurchaseItem

  attributes :id

  typelize :string
  attribute :path do |purchase_item|
    purchase_path(purchase_item.purchase)
  end

  typelize :string
  attribute :supplier_title do |purchase_item|
    purchase_item.purchase.supplier.title
  end

  typelize :string, nullable: true
  attribute :purchase_date do |purchase_item|
    format_date(purchase_item.purchase.date)
  end

  typelize :string, nullable: true
  attribute :item_price do |purchase_item|
    format_money(purchase_item.purchase.item_price)
  end

  typelize :string
  attribute :tracking_number do |purchase_item|
    purchase_item.tracking_number.to_s
  end

  typelize :string
  attribute :shipping_company_name do |purchase_item|
    purchase_item.shipping_company&.name.to_s
  end

  typelize :string, nullable: true
  attribute :shipped_at do |purchase_item|
    format_date(purchase_item.shipped_at)
  end

  typelize :string
  attribute :unlink_path do |purchase_item|
    purchase_item_sale_item_link_path(purchase_item)
  end

  typelize :string
  attribute :current_warehouse_name do |purchase_item|
    purchase_item.warehouse.name
  end

  typelize :string, nullable: true
  attribute :current_warehouse_moved_in do |purchase_item|
    format_date(purchase_item.current_warehouse_arrived_at)
  end

  typelize :string
  attribute :current_warehouse_path do |purchase_item|
    warehouse_path(purchase_item.warehouse, selected: purchase_item.id, anchor: purchase_item.id)
  end

  typelize "Array<{ moved_in: string | null; warehouse_name: string | null }>"
  attribute :warehouse_movements do |purchase_item|
    purchase_item.warehouse_movements.sort_by(&:moved_in).reverse.map do |movement|
      {moved_in: format_datetime(movement.moved_in), warehouse_name: movement.warehouse&.name}
    end
  end
end
