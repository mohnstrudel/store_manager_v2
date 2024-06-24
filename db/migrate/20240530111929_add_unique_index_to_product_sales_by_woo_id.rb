class AddUniqueIndexToProductSalesByWooId < ActiveRecord::Migration[7.1]
  def change
    add_index :product_sales, :woo_id, unique: true
  end
end
