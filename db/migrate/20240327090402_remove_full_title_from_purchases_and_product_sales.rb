class RemoveFullTitleFromPurchasesAndSaleItems < ActiveRecord::Migration[7.1]
  def change
    remove_column :purchases, :full_title, :string
    remove_column :sale_items, :full_title, :string
  end
end
