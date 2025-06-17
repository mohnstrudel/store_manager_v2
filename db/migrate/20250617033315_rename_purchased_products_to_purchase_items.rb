class RenamePurchaseItemsToPurchaseItems < ActiveRecord::Migration[8.0]
  def change
    StrongMigrations.disable_check(:rename_table)

    rename_table :purchase_items, :purchase_items
  end
end
