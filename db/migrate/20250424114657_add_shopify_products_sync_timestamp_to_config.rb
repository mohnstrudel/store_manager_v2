class AddShopifyProductsSyncTimestampToConfig < ActiveRecord::Migration[8.0]
  def change
    add_column :configs, :shopify_products_sync, :datetime
  end
end
