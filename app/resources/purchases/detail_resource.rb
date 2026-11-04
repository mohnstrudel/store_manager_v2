# frozen_string_literal: true

class Purchases::DetailResource < PurchaseResource
  typelize :string
  attribute :destroy_path do |purchase|
    purchase_path(purchase)
  end

  typelize :string, nullable: true
  attribute :product_path do |purchase|
    purchase_product_path(purchase)
  end

  typelize :string, nullable: true
  attribute :product_image_url do |purchase|
    purchase_product_image_url(purchase)
  end

  typelize :string, nullable: true
  attribute :item_price do |purchase|
    format_money(purchase.item_price)
  end

  typelize :string, nullable: true
  attribute :cost_total do |purchase|
    format_money(purchase.cost_total)
  end

  typelize :string, nullable: true
  attribute :shipping_total do |purchase|
    format_money(purchase.shipping_total)
  end

  typelize :string, nullable: true
  attribute :expenses_total do |purchase|
    format_money(purchase.expenses_total)
  end

  typelize :string, nullable: true
  attribute :paid do |purchase|
    format_money(purchase.paid)
  end

  typelize :string, nullable: true
  attribute :debt do |purchase|
    format_money(purchase.debt)
  end

  typelize :string
  attribute :supplier_path do |purchase|
    supplier_path(purchase.supplier)
  end

  typelize :string
  attribute :date do |purchase|
    format_date(purchase.date)
  end
end
