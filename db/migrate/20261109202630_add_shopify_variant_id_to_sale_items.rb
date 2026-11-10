# frozen_string_literal: true

class AddShopifyVariantIdToSaleItems < ActiveRecord::Migration[8.1]
  def change
    add_column :sale_items, :shopify_variant_id, :string
  end
end
