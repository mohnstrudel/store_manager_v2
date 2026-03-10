# frozen_string_literal: true

class BackfillStoreInfoSlugFromProductsStoreLink < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Use safety_assured since we're doing data migration, not schema changes
    safety_assured { backfill_slug_from_products }
    safety_assured { backfill_slug_from_editions }
  end

  def down
    # Clear backfilled slug values
    safety_assured { clear_backfilled_slugs }
  end

  private

  def backfill_slug_from_products
    say "Backfilling StoreInfo.slug from products.store_link for Shopify products..."

    execute <<~SQL.squish
      UPDATE store_infos
      SET slug = products.store_link,
          updated_at = NOW()
      FROM products
      WHERE store_infos.storable_type = 'Product'
        AND store_infos.storable_id = products.id
        AND store_infos.store_name = 1
        AND products.store_link IS NOT NULL
        AND products.store_link != ''
        AND (store_infos.slug IS NULL OR store_infos.slug = '')
    SQL

    count = execute <<~SQL.squish
      SELECT COUNT(*)
      FROM store_infos si
      JOIN products p ON si.storable_type = 'Product' AND si.storable_id = p.id
      WHERE si.store_name = 1
        AND p.store_link IS NOT NULL
        AND p.store_link != ''
        AND si.slug = p.store_link
    SQL

    say "  - Updated #{count.first["count"]} StoreInfo.slug values for Shopify products"
  end

  def backfill_slug_from_editions
    say "Backfilling StoreInfo.slug from editions.store_link for WooCommerce editions..."

    execute <<~SQL.squish
      UPDATE store_infos
      SET slug = editions.store_link,
          updated_at = NOW()
      FROM editions
      WHERE store_infos.storable_type = 'Edition'
        AND store_infos.storable_id = editions.id
        AND store_infos.store_name = 2
        AND editions.store_link IS NOT NULL
        AND editions.store_link != ''
        AND (store_infos.slug IS NULL OR store_infos.slug = '')
    SQL

    count = execute <<~SQL.squish
      SELECT COUNT(*)
      FROM store_infos si
      JOIN editions e ON si.storable_type = 'Edition' AND si.storable_id = e.id
      WHERE si.store_name = 2
        AND e.store_link IS NOT NULL
        AND e.store_link != ''
        AND si.slug = e.store_link
    SQL

    say "  - Updated #{count.first["count"]} StoreInfo.slug values for WooCommerce editions"
  end

  def clear_backfilled_slugs
    say "Clearing backfilled slug values from StoreInfo..."
    execute <<~SQL.squish
      UPDATE store_infos
      SET slug = NULL,
          updated_at = NOW()
      WHERE storable_type IN ('Product', 'Edition')
        AND slug IS NOT NULL
    SQL
  end
end
