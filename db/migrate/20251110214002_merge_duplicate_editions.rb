class MergeDuplicateEditions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class MigrationEdition < ApplicationRecord
    self.table_name = "editions"
  end

  class MigrationSaleItem < ApplicationRecord
    self.table_name = "sale_items"
  end

  class MigrationPurchase < ApplicationRecord
    self.table_name = "purchases"
  end

  def up
    # Step 1: Find all duplicate groups and their primary edition (smallest ID)
    duplicate_groups = MigrationEdition
      .select(:product_id, :size_id, :version_id, :color_id)
      .group(:product_id, :size_id, :version_id, :color_id)
      .having("COUNT(*) > 1")

    duplicate_groups.each do |group|
      # Find all editions with these attributes, ordered by ID (primary first)
      editions = MigrationEdition
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
      MigrationSaleItem.where(edition_id: duplicate_editions.pluck(:id))
        .update_all(edition_id: primary_edition.id)

      # Step 3: Transfer purchases to primary edition
      MigrationPurchase.where(edition_id: duplicate_editions.pluck(:id))
        .update_all(edition_id: primary_edition.id)

      # Step 4: Delete duplicate editions
      MigrationEdition.where(id: duplicate_editions.pluck(:id)).delete_all
    end
  end

  def down
    # This migration is not reversible - we cannot restore deleted records
    raise ActiveRecord::IrreversibleMigration
  end
end
