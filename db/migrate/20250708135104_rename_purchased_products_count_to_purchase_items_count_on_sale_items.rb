class RenamePurchasedProductsCountToPurchaseItemsCountOnSaleItems < ActiveRecord::Migration[8.0]
  def up
    add_column :sale_items, :purchase_items_count, :integer, default: 0, null: false
  end

  def down
    remove_column :sale_items, :purchase_items_count
  end
end
