class AddShopifyIdToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :shopify_id, :string
    add_index :products, :shopify_id
  end
end
