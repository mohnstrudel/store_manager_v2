# frozen_string_literal: true

class BrokenSales::PurchaseResource < BrokenSales::AssignmentResource
  typelize_from Purchase

  typelize '"purchase"'
  attribute :kind do |_purchase|
    "purchase"
  end

  typelize :string
  attribute :reference do |purchase|
    purchase.order_reference.presence || "Purchase ##{purchase.id}"
  end

  typelize :number
  attribute :inventory_units do |purchase|
    purchase.purchase_items.size
  end

  typelize :number
  attribute :linked_units do |purchase|
    purchase.purchase_items.count { |purchase_item| purchase_item.sale_item_id.present? }
  end

  typelize :string
  attribute :record_path do |purchase|
    purchase_path(purchase)
  end
end
