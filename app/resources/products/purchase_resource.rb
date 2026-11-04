# frozen_string_literal: true

class Products::PurchaseResource < ApplicationResource
  typelize_from Purchase

  attributes :id

  typelize :string
  attribute :path do |purchase|
    purchase_path(purchase)
  end

  typelize :string
  attribute :supplier do |purchase|
    purchase.supplier.title
  end

  typelize :string
  attribute :order_reference do |purchase|
    purchase.order_reference.to_s
  end

  typelize :string, nullable: true
  attribute :variant_title do |purchase|
    purchase.variant&.title
  end

  typelize :string, nullable: true
  attribute :item_price do |purchase|
    format_money(purchase.item_price)
  end

  typelize :number
  attribute :amount, &:amount

  typelize :string
  attribute :created_at do |purchase|
    format_date(purchase.created_at)
  end

  typelize "Array<{ id: number; name: string | null }>"
  attribute :warehouses do |purchase|
    purchase.purchase_items.map { |purchase_item| {id: purchase_item.id, name: purchase_item.warehouse&.name} }
  end
end
