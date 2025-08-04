class RenameVariationsToEditions < ActiveRecord::Migration[8.0]
  def change
    rename_table :variations, :editions
    rename_column :product_sales, :variation_id, :edition_id
    rename_column :purchases, :variation_id, :edition_id
  end
end
