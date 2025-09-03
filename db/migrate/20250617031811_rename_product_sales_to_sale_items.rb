class RenameProductSalesToSaleItems < ActiveRecord::Migration[8.0]
  def change
    StrongMigrations.disable_check(:rename_table)
    StrongMigrations.disable_check(:rename_column)

    rename_table :product_sales, :sale_items

    rename_column :purchased_products, :product_sale_id, :sale_item_id
  end
end
