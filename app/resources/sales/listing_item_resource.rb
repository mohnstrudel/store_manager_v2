# frozen_string_literal: true

class Sales::ListingItemResource < ApplicationResource
  typelize_from SaleItem

  attributes :id

  typelize :string
  attribute :title, &:title

  attributes :qty

  typelize :number
  attribute :purchased_count do |item|
    item.purchase_items.size
  end

  typelize :string, nullable: true
  attribute :product_thumb_url do |item|
    thumb_url(item.product)
  end

  typelize "Array<{ id: number; path: string; warehouse_name: string; expenses: string | null }>"
  attribute :purchase_items do |item|
    item.purchase_items.map do |purchase_item|
      {
        id: purchase_item.id,
        path: purchase_item_path(purchase_item),
        warehouse_name: purchase_item.warehouse.name,
        expenses: format_money(purchase_item.expenses)
      }
    end
  end
end
