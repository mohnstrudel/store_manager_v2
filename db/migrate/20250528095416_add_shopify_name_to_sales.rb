class AddShopifyNameToSales < ActiveRecord::Migration[8.0]
  def change
    add_column :sales, :shopify_name, :string
  end
end
