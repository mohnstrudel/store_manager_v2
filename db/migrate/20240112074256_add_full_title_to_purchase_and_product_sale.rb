class AddFullTitleToPurchaseAndSaleItem < ActiveRecord::Migration[7.1]
  def change
    add_column :purchases, :full_title, :string
    add_column :sale_items, :full_title, :string
  end
end
