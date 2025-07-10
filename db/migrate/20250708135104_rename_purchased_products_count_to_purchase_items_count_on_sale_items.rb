class RenamePurchasedProductsCountToPurchaseItemsCountOnSaleItems < ActiveRecord::Migration[8.0]
  def up
    add_column :sale_items, :purchase_items_count, :integer, default: 0, null: false
    SaleItem.reset_column_information
    SaleItem.find_each do |item|
      item.update_column(:purchase_items_count, item.purchased_products_count)
    end
  end

  def down
    remove_column :sale_items, :purchase_items_count
  end
end
