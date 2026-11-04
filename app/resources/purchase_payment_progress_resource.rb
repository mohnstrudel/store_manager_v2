# frozen_string_literal: true

class PurchasePaymentProgressResource < ApplicationResource
  typelize :number
  attribute :progress do |purchase|
    purchase.progress.to_f
  end

  typelize :string, nullable: true
  attribute :paid do |purchase|
    format_money(purchase.item_paid)
  end

  typelize :string, nullable: true
  attribute :price do |purchase|
    format_money(purchase.item_price)
  end

  typelize :string, nullable: true
  attribute :debt do |purchase|
    format_money(purchase.item_debt)
  end
end
