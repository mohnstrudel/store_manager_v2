# frozen_string_literal: true

class MoveProductSkuToBaseEditions < ActiveRecord::Migration[8.1]
  class MigrationProduct < ApplicationRecord
    self.table_name = "products"
  end

  class MigrationEdition < ApplicationRecord
    self.table_name = "editions"
  end

  def up
    backfill_base_editions_and_skus!
    change_column_null :editions, :sku, false

    remove_index :products, :sku if index_exists?(:products, :sku)
    remove_column :products, :sku if column_exists?(:products, :sku)
  end

  def down
    add_column :products, :sku, :string unless column_exists?(:products, :sku)
    add_index :products, :sku, unique: true unless index_exists?(:products, :sku)
    change_column_null :editions, :sku, true
  end

  private

  def backfill_base_editions_and_skus!
    total_products = MigrationProduct.count
    generated_skus = 0
    collision_adjustments = 0

    say_with_time("Backfilling base editions and edition SKUs for #{total_products} products") do
      MigrationProduct.find_each do |product|
        base_edition = find_or_create_base_edition_for(product)

        preferred_sku = product[:sku].presence || base_edition.sku.presence || deterministic_base_sku(product.id)
        sku, bumped = resolve_available_sku(preferred_sku, except_edition_id: base_edition.id)
        collision_adjustments += 1 if bumped
        generated_skus += 1 if base_edition.sku.blank?
        base_edition.update_columns(sku:, updated_at: Time.current) if base_edition.sku != sku
      end

      MigrationEdition.where(sku: [nil, ""]).find_each do |edition|
        preferred_sku = deterministic_edition_sku(edition.id, edition.product_id)
        sku, bumped = resolve_available_sku(preferred_sku, except_edition_id: edition.id)
        collision_adjustments += 1 if bumped
        edition.update_columns(sku:, updated_at: Time.current)
        generated_skus += 1
      end
    end

    say("Generated or replaced SKU values: #{generated_skus}")
    say("SKU collision adjustments applied: #{collision_adjustments}")
  end

  def find_or_create_base_edition_for(product)
    base_edition = MigrationEdition.find_by(
      product_id: product.id,
      size_id: nil,
      version_id: nil,
      color_id: nil
    )
    return base_edition if base_edition

    MigrationEdition.create!(
      product_id: product.id,
      size_id: nil,
      version_id: nil,
      color_id: nil,
      selling_price: 0,
      purchase_cost: 0,
      weight: 0,
      sku: nil
    )
  end

  def deterministic_base_sku(product_id)
    "product-#{product_id}-base"
  end

  def deterministic_edition_sku(edition_id, product_id)
    "product-#{product_id}-edition-#{edition_id}"
  end

  def resolve_available_sku(seed_sku, except_edition_id:)
    return [seed_sku, false] unless sku_taken?(seed_sku, except_edition_id:)

    suffix = 2
    loop do
      candidate = "#{seed_sku}-#{suffix}"
      return [candidate, true] unless sku_taken?(candidate, except_edition_id:)

      suffix += 1
    end
  end

  def sku_taken?(sku, except_edition_id:)
    relation = MigrationEdition.where(sku:)
    relation = relation.where.not(id: except_edition_id) if except_edition_id.present?
    relation.exists?
  end
end
