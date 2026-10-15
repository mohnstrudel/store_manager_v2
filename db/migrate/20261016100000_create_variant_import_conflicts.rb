# frozen_string_literal: true

class CreateVariantImportConflicts < ActiveRecord::Migration[8.1]
  def change
    create_table :variant_import_conflicts do |t|
      t.references :product, null: false, foreign_key: {on_delete: :cascade}
      t.references :conflicting_variant, foreign_key: {to_table: :variants, on_delete: :nullify}
      t.string :store_id, null: false
      t.string :sku
      t.jsonb :options, null: false, default: []
      t.timestamps
    end

    add_index :variant_import_conflicts, :store_id, unique: true
  end
end
