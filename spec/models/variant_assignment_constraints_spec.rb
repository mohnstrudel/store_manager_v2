# frozen_string_literal: true

require "rails_helper"

RSpec.describe "final Variant assignment database constraints" do
  let(:connection) { ActiveRecord::Base.connection }

  before do
    next if connection.indexes(:variants).any? { |index|
      index.name == "index_variants_on_product_and_id"
    }

    skip(
      "Final contraction is staged until Variant::AssignmentContractionGate " \
        "reports zero in development"
    )
  end

  it "makes Product and Variant identity non-null on every transaction record" do
    nullable_identity_columns = {
      purchases: %w[product_id variant_id],
      sale_items: %w[product_id variant_id],
      purchase_items: %w[product_id variant_id]
    }.flat_map do |table, columns|
      connection.columns(table).filter_map do |column|
        "#{table}.#{column.name}" if column.name.in?(columns) && column.null
      end
    end

    expect(nullable_identity_columns).to be_empty
  end

  it "enforces same-Product Variant identity and exact PurchaseItem parent identity" do
    foreign_keys = %w[
      fk_purchases_variant_identity
      fk_sale_items_variant_identity
      fk_purchase_items_variant_identity
      fk_purchase_items_purchase_identity
      fk_purchase_items_sale_item_identity
    ]

    expect(
      foreign_keys.index_with { |name|
        table =
          if name.include?("purchase_items")
            :purchase_items
          elsif name.include?("purchases")
            :purchases
          else
            :sale_items
          end

        connection
          .foreign_keys(table)
          .any? { |foreign_key| foreign_key.options[:name] == name }
      }
    ).to all(satisfy { |_name, exists| exists })
  end

  it "enforces one Base Model per Product" do
    index = connection.indexes(:variants).find { |candidate|
      candidate.name == "index_variants_on_one_base_model_per_product"
    }

    expect(index).to have_attributes(unique: true, columns: ["product_id"])
    expect(index.where).to include(
      "size_id IS NULL",
      "version_id IS NULL",
      "color_id IS NULL"
    )
  end

  it "enforces nonblank Variant StoreInfo identity uniqueness within a store" do
    index = connection.indexes(:store_infos).find { |candidate|
      candidate.name == "index_variant_store_infos_on_store_and_external_id"
    }

    expect(index).to have_attributes(
      unique: true,
      columns: %w[store_name store_id]
    )
    expect(index.where).to match(/storable_type.*Variant/i)
    expect(index.where).to match(/store_id IS NOT NULL/i)
    expect(index.where).to match(/btrim.*store_id.*<>/i)
  end
end
