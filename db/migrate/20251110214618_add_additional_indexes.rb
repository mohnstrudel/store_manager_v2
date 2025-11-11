class AddAdditionalIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Do not save editions with the same store id
    add_unique_index_if_not_exists :editions, :shopify_id, where: "shopify_id IS NOT NULL"
    add_unique_index_if_not_exists :editions, :woo_id, where: "woo_id IS NOT NULL"

    # Prevent race conditions
    add_unique_index_if_not_exists :product_sizes, [:product_id, :size_id]
    add_unique_index_if_not_exists :product_versions, [:product_id, :version_id]
    add_unique_index_if_not_exists :product_colors, [:product_id, :color_id]

    # Product attributes unique index with COALESCE for NULL handling
    remove_index_if_exists :editions, name: "index_editions_on_product_attributes_unique"
    add_index :editions,
      "(product_id, COALESCE(size_id, -1), COALESCE(version_id, -1), COALESCE(color_id, -1))",
      unique: true,
      algorithm: :concurrently,
      name: "index_editions_on_product_attributes_unique"
  end

  private

  def add_unique_index_if_not_exists(table, columns, **options)
    return if index_exists?(table, columns, **options.except(:algorithm))

    add_index table, columns, {unique: true, algorithm: :concurrently}.merge(options)
  end

  def remove_index_if_exists(table, **options)
    return unless index_exists?(table, **options)
    remove_index table, **options.except(:algorithm)
  end
end
