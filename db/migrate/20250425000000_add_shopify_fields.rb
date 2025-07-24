class AddShopifyFields < ActiveRecord::Migration[8.0]
  def change
    add_column :sales, :shopify_id, :string
    add_column :sales, :shopify_created_at, :datetime
    add_column :sales, :shopify_updated_at, :datetime

    add_column :product_sales, :shopify_id, :string

    add_column :customers, :shopify_id, :string

    add_index :sales, :shopify_id
    add_index :product_sales, :shopify_id
    add_index :customers, :shopify_id
  end
end
