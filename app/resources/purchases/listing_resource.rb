# frozen_string_literal: true

class Purchases::ListingResource < PurchaseResource
  typelize :number
  attribute :purchase_items_count do |purchase|
    purchase.purchase_items.size
  end

  typelize "Array<{ warehouse_name: string; count: number }>"
  attribute :warehouse_counts do |purchase|
    purchase.purchase_items.group_by(&:warehouse).map do |warehouse, purchase_items|
      {warehouse_name: warehouse.name, count: purchase_items.count}
    end
  end
end
