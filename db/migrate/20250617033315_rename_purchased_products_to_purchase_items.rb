class RenamePurchasedProductsToPurchaseItems < ActiveRecord::Migration[8.0]
  def change
    StrongMigrations.disable_check(:rename_table)

    rename_table :purchased_products, :purchase_items
  end
end
