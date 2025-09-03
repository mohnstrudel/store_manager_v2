class RemovePurchasedProductsCountFromSaleItems < ActiveRecord::Migration[8.0]
  def up
    safety_assured { remove_column :sale_items, :purchased_products_count }
  end

  def down
    add_column :sale_items, :purchased_products_count, :integer, default: 0, null: false
    SaleItem.reset_column_information
    SaleItem.find_each do |item|
      item.update_column(:purchased_products_count, item.purchase_items_count)
    end
  end
end
