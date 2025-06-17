class RenameWarehouseProductToPurchaseItem < ActiveRecord::Migration[7.1]
  def change
    rename_table :warehouse_products, :purchase_items
  end
end
