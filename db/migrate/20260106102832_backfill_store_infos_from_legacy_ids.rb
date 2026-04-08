# frozen_string_literal: true

class BackfillStoreInfosFromLegacyIds < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    backfill_store_infos

    # Add indexes for performance after data is backfilled (concurrently to avoid blocking)
    add_index :store_infos, [:store_name, :store_id], name: "index_store_infos_on_store_name_and_store_id", algorithm: :concurrently
    add_index :store_infos, [:storable_type, :storable_id, :store_name], name: "index_store_infos_on_storable_and_store_name", unique: true, algorithm: :concurrently
  end

  def down
    # Remove indexes
    remove_index :store_infos, name: "index_store_infos_on_storable_and_store_name"
    remove_index :store_infos, name: "index_store_infos_on_store_name_and_store_id"

    # Delete backfilled StoreInfo records
    delete_backfilled_store_infos
  end

  private

  def backfill_store_infos
    # Backfill Products
    backfill_model("Product", :products)

    # Backfill Sales
    backfill_model("Sale", :sales)

    # Backfill Customers
    backfill_model("Customer", :customers)

    # Backfill Editions
    backfill_model("Edition", :editions)

    # Backfill SaleItems
    backfill_model("SaleItem", :sale_items)
  end

  def backfill_model(model_name, table_name)
    say "Backfilling StoreInfo for #{model_name}..."

    # Backfill Shopify IDs
    execute <<~SQL.squish
      INSERT INTO store_infos (storable_type, storable_id, store_name, store_id, created_at, updated_at)
      SELECT '#{model_name}', id, 1, shopify_id, NOW(), NOW()
      FROM #{table_name}
      WHERE shopify_id IS NOT NULL
      AND shopify_id != ''
      ON CONFLICT (storable_type, storable_id, store_name) DO NOTHING
    SQL

    shopify_count = execute <<~SQL.squish
      SELECT COUNT(*) FROM #{table_name} WHERE shopify_id IS NOT NULL AND shopify_id != ''
    SQL
    say "  - Created #{shopify_count.first["count"]} Shopify StoreInfo records for #{model_name}"

    # Backfill Woo IDs
    execute <<~SQL.squish
      INSERT INTO store_infos (storable_type, storable_id, store_name, store_id, created_at, updated_at)
      SELECT '#{model_name}', id, 2, woo_id, NOW(), NOW()
      FROM #{table_name}
      WHERE woo_id IS NOT NULL
      AND woo_id != ''
      ON CONFLICT (storable_type, storable_id, store_name) DO NOTHING
    SQL

    woo_count = execute <<~SQL.squish
      SELECT COUNT(*) FROM #{table_name} WHERE woo_id IS NOT NULL AND woo_id != ''
    SQL
    say "  - Created #{woo_count.first["count"]} Woo StoreInfo records for #{model_name}"
  end

  def delete_backfilled_store_infos
    say "Deleting backfilled StoreInfo records..."

    execute <<~SQL.squish
      DELETE FROM store_infos
      WHERE storable_type IN ('Product', 'Sale', 'Customer', 'Edition', 'SaleItem')
    SQL
  end
end
