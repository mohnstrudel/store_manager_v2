# frozen_string_literal: true

require "rails_helper"
require Rails.root.join(
  ".specs/174-expenses/20260803T220023Z__variant-assignments-repair/artifacts/" \
    "20260731120000_contract_variant_assignments"
)

RSpec.describe ContractVariantAssignments do
  let(:migration) { described_class.new }

  describe "#up" do
    it "performs no schema change when the live zero gate refuses contraction" do
      allow(Variant::AssignmentContractionGate)
        .to receive(:verify!)
        .and_raise(
          Variant::AssignmentContractionGate::IntegrityError,
          "purchases=44 sale_items=81"
        )
      expect(migration).not_to receive(:add_index)
      expect(migration).not_to receive(:add_foreign_key)
      expect(migration).not_to receive(:change_column_null)

      expect { migration.up }
        .to raise_error(
          Variant::AssignmentContractionGate::IntegrityError,
          /purchases=44 sale_items=81/
        )
    end

    it "stages every approved final constraint after a clean gate" do
      events = []
      allow(Variant::AssignmentContractionGate).to receive(:verify!) {
        events << :zero_gate
      }
      allow(migration).to receive(:add_index) { |table, columns, **options|
        events << [:add_index, table, columns, options[:name]]
      }
      allow(migration).to receive(:add_foreign_key) { |table, target, **options|
        events << [:add_foreign_key, table, target, options[:name]]
      }
      allow(migration).to receive(:validate_foreign_key)
      allow(migration).to receive(:change_column_null) { |table, column, null|
        events << [:change_column_null, table, column, null]
      }

      migration.up

      expect(events.first).to eq(:zero_gate)
      expect(events).to include(
        [:add_index, :variants, %i[product_id id], "index_variants_on_product_and_id"],
        [:add_index, :variants, :product_id, "index_variants_on_one_base_model_per_product"],
        [:add_index, :store_infos, %i[store_name store_id], "index_variant_store_infos_on_store_and_external_id"],
        [:add_foreign_key, :purchases, :variants, "fk_purchases_variant_identity"],
        [:add_foreign_key, :sale_items, :variants, "fk_sale_items_variant_identity"],
        [:add_foreign_key, :purchase_items, :variants, "fk_purchase_items_variant_identity"],
        [:change_column_null, :purchases, :product_id, false],
        [:change_column_null, :purchases, :variant_id, false],
        [:change_column_null, :sale_items, :variant_id, false],
        [:change_column_null, :purchase_items, :product_id, false],
        [:change_column_null, :purchase_items, :variant_id, false]
      )
    end
  end
end
