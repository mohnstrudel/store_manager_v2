# frozen_string_literal: true

class ClearShopifySyncTimes < ActiveRecord::Migration[8.1]
  def up
    Config.update_all(shopify_products_sync: nil, shopify_sales_sync: nil)
  end

  def down
  end
end
