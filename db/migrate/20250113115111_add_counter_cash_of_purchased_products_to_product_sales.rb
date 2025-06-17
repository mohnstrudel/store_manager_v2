class AddCounterCashOfPurchaseItemsToSaleItems < ActiveRecord::Migration[8.0]
  def up
    add_column :sale_items, :purchase_items_count, :integer, default: 0, null: false

    SaleItem.find_each do |ps|
      SaleItem.reset_counters(ps.id, :purchase_items)
    end
  end

  def down
    remove_column :sale_items, :purchase_items_count
  end
end
