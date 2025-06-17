class AddUniqueIndexToSaleItemsByWooId < ActiveRecord::Migration[7.1]
  def change
    add_index :sale_items, :woo_id, unique: true
  end
end
