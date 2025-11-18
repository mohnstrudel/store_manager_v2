class MergeDuplicateEditions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      # Step 1: Find all duplicate groups and their primary edition (smallest ID)
      duplicate_groups = Edition
        .select(:product_id, :size_id, :version_id, :color_id)
        .group(:product_id, :size_id, :version_id, :color_id)
        .having("COUNT(*) > 1")

      duplicate_groups.each do |group|
        # Find all editions with these attributes, ordered by ID (primary first)
        editions = Edition
          .where(
            product_id: group.product_id,
            size_id: group.size_id,
            version_id: group.version_id,
            color_id: group.color_id
          )
          .order(:id)

        primary_edition = editions.first
        duplicate_editions = editions.offset(1)

        # Step 2: Transfer sale_items to primary edition
        SaleItem.where(edition_id: duplicate_editions.pluck(:id))
          .update_all(edition_id: primary_edition.id)

        # Step 3: Transfer purchases to primary edition
        Purchase.where(edition_id: duplicate_editions.pluck(:id))
          .update_all(edition_id: primary_edition.id)

        # Step 4: Delete duplicate editions
        Edition.where(id: duplicate_editions.pluck(:id)).delete_all
      end
    end
  end

  def down
    # This migration is not reversible - we cannot restore deleted records
    raise ActiveRecord::IrreversibleMigration
  end
end
