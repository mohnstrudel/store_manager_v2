class AddRevenueFieldsToSales < ActiveRecord::Migration[8.1]
  def change
    change_table :sales, bulk: true do |t|
      t.decimal :expected_revenue, precision: 8, scale: 2
      t.decimal :received_revenue, precision: 8, scale: 2
      t.decimal :outstanding_revenue, precision: 8, scale: 2
      t.decimal :refunded_revenue, precision: 8, scale: 2
      t.decimal :net_payment, precision: 8, scale: 2
      t.string :payment_gateway_names, array: true, default: [], null: false
      t.string :payment_terms_name
      t.string :payment_terms_type
      t.datetime :payment_due
      t.boolean :payment_overdue, default: false, null: false
    end
  end
end
