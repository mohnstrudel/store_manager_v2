class CreatePurchases < ActiveRecord::Migration[7.0]
  def change
    create_table :purchases do |t|
      t.references :supplier, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :order_reference
      t.decimal :price, precision: 8, scale: 2
      t.integer :amount

      t.timestamps
    end
  end
end
