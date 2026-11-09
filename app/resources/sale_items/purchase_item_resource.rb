# frozen_string_literal: true

class SaleItems::PurchaseItemResource < ApplicationResource
  typelize_from PurchaseItem

  attributes :id

  typelize :string
  attribute :path do |purchase_item|
    purchase_item_path(purchase_item)
  end

  typelize :string
  attribute :edit_path do |purchase_item|
    edit_purchase_item_path(purchase_item, redirect_to_sale_item: true)
  end

  typelize :string
  attribute :unlink_path do |purchase_item|
    purchase_item_sale_item_link_path(purchase_item)
  end

  typelize :string
  attribute :warehouse_name do |purchase_item|
    purchase_item.warehouse.name
  end

  typelize :string
  attribute :size do |purchase_item|
    format_item_size(purchase_item)
  end

  typelize :string
  attribute :weight do |purchase_item|
    purchase_item.weight.to_s
  end

  typelize :string, nullable: true
  attribute :expenses do |purchase_item|
    format_money(purchase_item.expenses)
  end

  typelize :string, nullable: true
  attribute :shipping_cost do |purchase_item|
    format_money(purchase_item.shipping_cost)
  end
end
