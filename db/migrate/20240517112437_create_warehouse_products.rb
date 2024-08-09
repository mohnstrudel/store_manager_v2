class CreateWarehouseProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :warehouse_products do |t|
      t.references :warehouse, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :weight
      t.integer :length
      t.integer :width
      t.integer :height
      t.decimal :price, precision: 8, scale: 2
      t.decimal :shipping_price, precision: 8, scale: 2
      t.string :tracking_number

      t.timestamps
    end
  end
end
