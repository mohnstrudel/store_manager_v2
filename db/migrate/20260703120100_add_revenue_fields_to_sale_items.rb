class AddRevenueFieldsToSaleItems < ActiveRecord::Migration[8.1]
  def change
    change_table :sale_items, bulk: true do |t|
      t.decimal :expected_revenue, precision: 8, scale: 2
      t.decimal :received_revenue, precision: 8, scale: 2
      t.decimal :outstanding_revenue, precision: 8, scale: 2
      t.decimal :refunded_revenue, precision: 8, scale: 2
    end
  end
end
