# frozen_string_literal: true

class AddVariantIdentityToPurchaseItems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :purchase_items, :product_id, :bigint
    add_column :purchase_items, :variant_id, :bigint

    add_index :purchases,
      %i[id product_id variant_id],
      unique: true,
      algorithm: :concurrently,
      name: "index_purchases_on_id_and_product_and_variant"
    add_index :sale_items,
      %i[id product_id variant_id],
      unique: true,
      algorithm: :concurrently,
      name: "index_sale_items_on_id_and_product_and_variant"
    add_index :purchase_items,
      %i[purchase_id product_id variant_id],
      algorithm: :concurrently,
      name: "index_purchase_items_on_purchase_and_identity"
    add_index :purchase_items,
      %i[sale_item_id product_id variant_id],
      algorithm: :concurrently,
      name: "index_purchase_items_on_sale_item_and_identity"

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
