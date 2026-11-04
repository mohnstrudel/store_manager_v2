# frozen_string_literal: true

class PurchaseItems::DetailResource < ApplicationResource
  include ApplicationHelper

  typelize_from PurchaseItem

  attributes :id

  typelize :string
  attribute :path do |purchase_item|
    purchase_item_path(purchase_item)
  end

  typelize :string
  attribute :edit_path do |purchase_item|
    edit_purchase_item_path(purchase_item)
  end

  typelize :string
  attribute :destroy_path do |purchase_item|
    purchase_item_path(purchase_item)
  end

  typelize :string
  attribute :purchase_path do |purchase_item|
    purchase_path(purchase_item.purchase)
  end

  typelize :string
  attribute :purchase_title do |purchase_item|
    purchase_item.purchase.full_title
  end

  typelize :string, nullable: true
  attribute :sale_path do |purchase_item|
    sale_path(purchase_item.sale) if purchase_item.sale
  end

  typelize :string, nullable: true
  attribute :sale_item_path do |purchase_item|
    sale_item_path(purchase_item.sale, purchase_item.sale_item) if purchase_item.sale_item
  end

  typelize :string
  attribute :supplier_title do |purchase_item|
    purchase_item.purchase.supplier.title
  end

  typelize :string
  attribute :supplier_path do |purchase_item|
    supplier_path(purchase_item.purchase.supplier)
  end

  typelize :string
  attribute :product_title do |purchase_item|
    purchase_product_title(purchase_item.purchase)
  end

  typelize :string, nullable: true
  attribute :product_path do |purchase_item|
    purchase_product_path(purchase_item.purchase)
  end

  typelize :string
  attribute :warehouse_name do |purchase_item|
    purchase_item.warehouse.name
  end

  typelize :string
  attribute :warehouse_path do |purchase_item|
    warehouse_path(purchase_item.warehouse)
  end

  typelize :string, nullable: true
  attribute :expenses do |purchase_item|
    format_money(purchase_item.expenses)
  end

  typelize :string, nullable: true
  attribute :shipping_cost do |purchase_item|
    format_money(purchase_item.shipping_cost)
  end

  typelize :string, nullable: true
  attribute :tracking_number do |purchase_item|
    safe_blank_render(purchase_item.tracking_number)
  end

  typelize :string, nullable: true
  attribute :shipping_company_name do |purchase_item|
    safe_blank_render(purchase_item.shipping_company&.name)
  end

  attributes :length, :width, :height, :weight

  typelize :string
  attribute :created_at do |purchase_item|
    format_date(purchase_item.created_at)
  end

  typelize :string
  attribute :updated_at do |purchase_item|
    format_date(purchase_item.updated_at)
  end

  typelize "Array<Media>"
  attribute :media do |purchase_item|
    MediaResource.attached(purchase_item.media)
  end

  typelize "Array<{ id: number; moved_in: string; warehouse_name: string | null; warehouse_path: string | null }>"
  attribute :warehouse_movements do |purchase_item|
    purchase_item.warehouse_movements.map.with_index do |movement, index|
      {
        id: index,
        moved_in: format_datetime(movement.moved_in),
        warehouse_name: movement.warehouse&.name,
        warehouse_path: movement.warehouse ? warehouse_path(movement.warehouse) : nil
      }
    end
  end
end
