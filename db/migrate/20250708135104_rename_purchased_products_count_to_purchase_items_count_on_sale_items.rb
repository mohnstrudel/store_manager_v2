class RenamePurchasedProductsCountToPurchaseItemsCountOnSaleItems < ActiveRecord::Migration[8.0]
  def up
    add_column :sale_items, :purchase_items_count, :integer, default: 0, null: false
    SaleItem.reset_column_information
    SaleItem.find_each do |sale_item|
      SaleItem.reset_counters(sale_item.id, :purchase_items)
    end
  end

  def down
    remove_column :sale_items, :purchase_items_count
  end
end
