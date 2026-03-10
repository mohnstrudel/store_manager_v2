# frozen_string_literal: true

class RenameShippingPriceOnPurchaseItems < ActiveRecord::Migration[8.1]
  def change
    change_table :purchase_items, bulk: true do |t|
      t.rename :shipping_price, :shipping_cost
      t.change_default :shipping_cost, from: nil, to: 0.00
      t.change_null :shipping_cost, false, 0.00
    end
  end
end
