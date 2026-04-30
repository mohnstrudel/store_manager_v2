# frozen_string_literal: true

class RenameEditionsToVariants < ActiveRecord::Migration[8.1]
  def up
    rename_table :editions, :variants
    rename_column :purchases, :edition_id, :variant_id
    rename_column :sale_items, :edition_id, :variant_id

    rename_variant_indexes
    rename_polymorphic_types("Edition", "Variant")
  end

  def down
    rename_polymorphic_types("Variant", "Edition")

    rename_column :sale_items, :variant_id, :edition_id
    rename_column :purchases, :variant_id, :edition_id
    rename_table :variants, :editions

    rename_edition_indexes
  end

  private

  def rename_variant_indexes
    rename_index_if_exists :variants, "index_editions_on_color_id", "index_variants_on_color_id"
    rename_index_if_exists :variants, "index_editions_on_deactivated_at", "index_variants_on_deactivated_at"
    rename_index_if_exists :variants, "index_editions_on_product_id", "index_variants_on_product_id"
    rename_index_if_exists :variants, "index_editions_on_product_attributes_unique", "index_variants_on_product_attributes_unique"
    rename_index_if_exists :variants, "index_editions_on_shopify_id", "index_variants_on_shopify_id"
    rename_index_if_exists :variants, "index_editions_on_size_id", "index_variants_on_size_id"
    rename_index_if_exists :variants, "index_editions_on_sku", "index_variants_on_sku"
    rename_index_if_exists :variants, "index_editions_on_version_id", "index_variants_on_version_id"
    rename_index_if_exists :variants, "index_editions_on_woo_id", "index_variants_on_woo_id"
    rename_index_if_exists :purchases, "index_purchases_on_edition_id", "index_purchases_on_variant_id"
    rename_index_if_exists :sale_items, "index_sale_items_on_edition_id", "index_sale_items_on_variant_id"
  end

  def rename_edition_indexes
    rename_index_if_exists :editions, "index_variants_on_color_id", "index_editions_on_color_id"
    rename_index_if_exists :editions, "index_variants_on_deactivated_at", "index_editions_on_deactivated_at"
    rename_index_if_exists :editions, "index_variants_on_product_id", "index_editions_on_product_id"
    rename_index_if_exists :editions, "index_variants_on_product_attributes_unique", "index_editions_on_product_attributes_unique"
    rename_index_if_exists :editions, "index_variants_on_shopify_id", "index_editions_on_shopify_id"
    rename_index_if_exists :editions, "index_variants_on_size_id", "index_editions_on_size_id"
    rename_index_if_exists :editions, "index_variants_on_sku", "index_editions_on_sku"
    rename_index_if_exists :editions, "index_variants_on_version_id", "index_editions_on_version_id"
    rename_index_if_exists :editions, "index_variants_on_woo_id", "index_editions_on_woo_id"
    rename_index_if_exists :purchases, "index_purchases_on_variant_id", "index_purchases_on_edition_id"
    rename_index_if_exists :sale_items, "index_sale_items_on_variant_id", "index_sale_items_on_edition_id"
  end

  def rename_index_if_exists(table_name, old_name, new_name)
    rename_index table_name, old_name, new_name if index_name_exists?(table_name, old_name)
  end

  def rename_polymorphic_types(from, to)
    execute sanitize_sql(["UPDATE store_infos SET storable_type = ? WHERE storable_type = ?", to, from])
    execute sanitize_sql(["UPDATE audits SET auditable_type = ? WHERE auditable_type = ?", to, from])
    execute sanitize_sql(["UPDATE audits SET associated_type = ? WHERE associated_type = ?", to, from])
  end

  def sanitize_sql(statement)
    ActiveRecord::Base.sanitize_sql_array(statement)
  end
end
