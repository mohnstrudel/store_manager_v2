# frozen_string_literal: true

class AddShippingCostToPurchases < ActiveRecord::Migration[8.1]
  def change
    add_column :purchases, :shipping_total, :decimal, precision: 8, scale: 2, null: false, default: 0.00

    backfill_total_shipping
  end

  def backfill_total_shipping
    Purchase.joins(:purchase_items).update_all(<<~SQL.squish)
      shipping_total = COALESCE((
        SELECT sum(purchase_items.shipping_cost)
        FROM purchase_items
        WHERE purchase_items.purchase_id = purchases.id
      ), 0)
    SQL
  end
end
