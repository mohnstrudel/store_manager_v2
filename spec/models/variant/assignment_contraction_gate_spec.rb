# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::AssignmentContractionGate do
  subject(:gate) { described_class.new(integrity:) }

  let(:integrity) { instance_double(Variant::AssignmentIntegrity) }

  describe "#verify!" do
    it "returns the zero audit snapshot when every contraction prerequisite is clean" do
      allow(integrity).to receive_messages(
        counts: {
          purchases: 0,
          sale_items: 0,
          purchase_item_links: 0
        },
        purchase_item_purchase_identity_mismatches: PurchaseItem.none
      )

      expect(gate.verify!).to eq(
        purchases: 0,
        sale_items: 0,
        purchase_item_links: 0,
        purchase_item_purchase_identity: 0,
        base_models: 0,
        base_activation: 0,
        duplicate_variant_store_identity: 0
      )
    end

    it "refuses contraction and reports every nonzero audit count" do
      purchase = create(:purchase)
      purchase.update_columns(variant_id: nil)
      allow(integrity).to receive_messages(
        counts: {
          purchases: 1,
          sale_items: 0,
          purchase_item_links: 0
        },
        purchase_item_purchase_identity_mismatches: PurchaseItem.none
      )

      expect { gate.verify! }
        .to raise_error(
          Variant::AssignmentContractionGate::IntegrityError,
          /purchases=1.*sale_items=0.*base_models=0.*base_activation=0.*duplicate_variant_store_identity=0/
        )
    end
  end
end
