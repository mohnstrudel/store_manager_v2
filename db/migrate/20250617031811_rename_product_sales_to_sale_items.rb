class RenameSaleItemsToSaleItems < ActiveRecord::Migration[8.0]
  def change
    StrongMigrations.disable_check(:rename_table)
    StrongMigrations.disable_check(:rename_column)

    rename_table :sale_items, :sale_items

    rename_column :purchase_items, :sale_item_id, :sale_item_id
  end
end
