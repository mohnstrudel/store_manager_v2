# frozen_string_literal: true

class ContractVariantAssignments < ActiveRecord::Migration[8.1]
  # Activation artifact: move this file into db/migrate only after
  # Variant::AssignmentContractionGate.verify! returns an all-zero snapshot.
  def up
    Variant::AssignmentContractionGate.verify!

    add_index :variants,
      %i[product_id id],
      unique: true,
      name: "index_variants_on_product_and_id"
    add_index :variants,
      :product_id,
      unique: true,
      where: "size_id IS NULL AND version_id IS NULL AND color_id IS NULL",
      name: "index_variants_on_one_base_model_per_product"
    add_index :store_infos,
      %i[store_name store_id],
      unique: true,
      where: <<~SQL.squish,
        storable_type = 'Variant'
        AND store_id IS NOT NULL
        AND BTRIM(store_id) <> ''
      SQL
      name: "index_variant_store_infos_on_store_and_external_id"

    add_variant_identity_foreign_key(:purchases, "fk_purchases_variant_identity")
    add_variant_identity_foreign_key(:sale_items, "fk_sale_items_variant_identity")
    add_variant_identity_foreign_key(:purchase_items, "fk_purchase_items_variant_identity")

    validate_foreign_key :purchase_items,
      name: "fk_purchase_items_purchase_identity"
    validate_foreign_key :purchase_items,
      name: "fk_purchase_items_sale_item_identity"

    change_column_null :purchases, :product_id, false
    change_column_null :purchases, :variant_id, false
    change_column_null :sale_items, :variant_id, false
    change_column_null :purchase_items, :product_id, false
    change_column_null :purchase_items, :variant_id, false
  end

  def down
    change_column_null :purchase_items, :variant_id, true
    change_column_null :purchase_items, :product_id, true
    change_column_null :sale_items, :variant_id, true
    change_column_null :purchases, :variant_id, true
    change_column_null :purchases, :product_id, true

    remove_foreign_key :purchase_items,
      name: "fk_purchase_items_variant_identity"
    remove_foreign_key :sale_items,
      name: "fk_sale_items_variant_identity"
    remove_foreign_key :purchases,
      name: "fk_purchases_variant_identity"

    restore_unvalidated_purchase_item_parent_foreign_keys

    remove_index :store_infos,
      name: "index_variant_store_infos_on_store_and_external_id"
    remove_index :variants,
      name: "index_variants_on_one_base_model_per_product"
    remove_index :variants,
      name: "index_variants_on_product_and_id"
  end

  private

  def add_variant_identity_foreign_key(table, name)
    add_foreign_key table,
      :variants,
      column: %i[product_id variant_id],
      primary_key: %i[product_id id],
      deferrable: :deferred,
      name:
  end

  def restore_unvalidated_purchase_item_parent_foreign_keys
    remove_foreign_key :purchase_items,
      name: "fk_purchase_items_sale_item_identity"
    remove_foreign_key :purchase_items,
      name: "fk_purchase_items_purchase_identity"

    add_foreign_key :purchase_items,
      :purchases,
      column: %i[purchase_id product_id variant_id],
      primary_key: %i[id product_id variant_id],
      deferrable: :deferred,
      validate: false,
      name: "fk_purchase_items_purchase_identity"
    add_foreign_key :purchase_items,
      :sale_items,
      column: %i[sale_item_id product_id variant_id],
      primary_key: %i[id product_id variant_id],
      deferrable: :deferred,
      validate: false,
      name: "fk_purchase_items_sale_item_identity"
  end
end
