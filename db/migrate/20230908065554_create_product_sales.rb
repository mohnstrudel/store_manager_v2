class CreateProductSales < ActiveRecord::Migration[7.0]
  def change
    create_table :product_sales do |t|
      t.decimal :price, precision: 8, scale: 2
      t.integer :qty
      t.belongs_to :product, null: false, foreign_key: true
      t.belongs_to :sale, null: false, foreign_key: true

      t.timestamps
    end
  end
end
