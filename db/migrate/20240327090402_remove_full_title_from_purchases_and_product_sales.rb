class RemoveFullTitleFromPurchasesAndProductSales < ActiveRecord::Migration[7.1]
  def change
    remove_column :purchases, :full_title, :string
    remove_column :product_sales, :full_title, :string
  end
end
