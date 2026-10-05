class AddOriginSaleItemToSaleItemsAndNonCatalogToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :sale_items, :origin_sale_item, foreign_key: {to_table: :sale_items}, null: true
    add_column :products, :non_catalog, :boolean, default: false, null: false
  end
end
