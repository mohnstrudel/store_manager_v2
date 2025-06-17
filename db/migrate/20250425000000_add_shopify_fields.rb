class AddShopifyFields < ActiveRecord::Migration[8.0]
  def change
    add_column :sales, :shopify_id, :string
    add_column :sales, :shopify_created_at, :datetime
    add_column :sales, :shopify_updated_at, :datetime

    add_column :sale_items, :shopify_id, :string

    add_column :customers, :shopify_id, :string

    add_index :sales, :shopify_id
    add_index :sale_items, :shopify_id
    add_index :customers, :shopify_id
  end
end
