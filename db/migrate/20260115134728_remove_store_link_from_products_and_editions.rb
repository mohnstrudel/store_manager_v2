# frozen_string_literal: true

class RemoveStoreLinkFromProductsAndEditions < ActiveRecord::Migration[8.1]
  def up
    # Remove store_link from products table
    remove_column :products, :store_link if column_exists?(:products, :store_link)

    # Remove store_link from editions table
    remove_column :editions, :store_link if column_exists?(:editions, :store_link)
  end

  def down
    # Add back store_link columns for rollback
    add_column :products, :store_link, :string
    add_column :editions, :store_link, :string
  end
end
