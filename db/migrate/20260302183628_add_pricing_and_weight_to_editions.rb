class AddPricingAndWeightToEditions < ActiveRecord::Migration[8.1]
  def change
    add_column :editions, :purchase_cost, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :editions, :selling_price, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :editions, :weight, :decimal, precision: 10, scale: 2, default: 0.0, null: false
  end
end
