class AddFullTitleToPurchaseAndProductSale < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :full_title, :string
    add_column :product_sales, :full_title, :string
  end
end
