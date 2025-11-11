class AddAdditionalIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Unique indexes on external store identifiers
    # Prevent duplication of editions during import from Shopify and WooCommerce
    # Each product from an external store must have a unique identifier in our system
    # where: "shopify_id IS NOT NULL" ensures that NULL values do not violate uniqueness
    add_unique_index_if_not_exists :editions, :shopify_id, where: "shopify_id IS NOT NULL"
    add_unique_index_if_not_exists :editions, :woo_id, where: "woo_id IS NOT NULL"

    # Unique indexes to prevent race conditions during parallel processing
    # Ensure that for each product there can be only one association with a specific size/version/color
    # Prevent creation of duplicate records during simultaneous execution of background synchronization tasks
    add_unique_index_if_not_exists :product_sizes, [:product_id, :size_id]
    add_unique_index_if_not_exists :product_versions, [:product_id, :version_id]
    add_unique_index_if_not_exists :product_colors, [:product_id, :color_id]

    # Composite unique index to prevent duplication of editions by product attributes
    # COALESCE(size_id, -1) replaces NULL values with -1 so that NULLs are not considered unique
    # This allows having multiple editions of the same product with NULL attributes, but prevents
    # duplication of editions with the same combinations of attributes (even if some of them are NULL)
    # For example: a product with size_id=1, version_id=NULL, color_id=2 will be unique,
    # but two editions with identical non-null attributes cannot be created
    remove_index_if_exists :editions, name: "index_editions_on_product_attributes_unique"
    add_index :editions,
      "product_id, COALESCE(size_id, -1), COALESCE(version_id, -1), COALESCE(color_id, -1)",
      unique: true,
      algorithm: :concurrently,
      name: "index_editions_on_product_attributes_unique"
  end

  def down
    # Remove product attributes unique index
    remove_index_if_exists :editions, name: "index_editions_on_product_attributes_unique"

    # Remove race condition prevention indexes (in reverse order)
    remove_index_if_exists :product_colors, columns: [:product_id, :color_id]
    remove_index_if_exists :product_versions, columns: [:product_id, :version_id]
    remove_index_if_exists :product_sizes, columns: [:product_id, :size_id]

    # Remove store id unique indexes (in reverse order)
    remove_index_if_exists :editions, columns: :woo_id, where: "woo_id IS NOT NULL"
    remove_index_if_exists :editions, columns: :shopify_id, where: "shopify_id IS NOT NULL"
  end

  private

  def add_unique_index_if_not_exists(table, columns, **options)
    return if index_exists?(table, columns, **options.except(:algorithm))

    add_index table, columns, unique: true, algorithm: :concurrently, **options
  end

  def remove_index_if_exists(table, columns: nil, **options)
    if columns
      return unless index_exists?(table, columns, **options)
      remove_index table, columns, **options.except(:algorithm)
    else
      return unless index_exists?(table, **options)
      remove_index table, **options.except(:algorithm)
    end
  end
end
