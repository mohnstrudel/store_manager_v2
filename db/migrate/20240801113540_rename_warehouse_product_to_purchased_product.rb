class RenameWarehouseProductToPurchasedProduct < ActiveRecord::Migration[7.1]
  def change
    rename_table :warehouse_products, :purchased_products
  end
end
