class AddShopifyIdToVariations < ActiveRecord::Migration[8.0]
  def change
    add_column :variations, :shopify_id, :string
    add_index :variations, :shopify_id
  end
end
