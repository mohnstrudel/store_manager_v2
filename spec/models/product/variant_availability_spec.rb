# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::VariantAvailability do
  describe "Base Model lifecycle" do
    it "creates one active Base Model for a new Product" do
      product = create(:product)

      expect(product.variants.select(&:base_model?)).to contain_exactly(product.base_variant)
      expect(product.base_variant).not_to be_deactivated
    end

    it "rejects a second Base Model" do
      product = create(:product)
      duplicate = product.variants.build(
        sku: "duplicate-base",
        size: nil,
        version: nil,
        color: nil
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to be_present
    end

    it "deactivates Base under the Product lock when the first real Variant becomes active" do
      product = create(:product)
      allow(product).to receive(:with_variant_availability_lock).and_call_original

      create(:variant, product:)

      expect(product).to have_received(:with_variant_availability_lock).at_least(:once)
      expect(product.base_variant.reload).to be_deactivated
    end

    it "reactivates Base under the Product lock when the last active real Variant is deactivated" do
      product = create(:product)
      variant = create(:variant, product:)
      allow(product).to receive(:with_variant_availability_lock).and_call_original

      variant.update!(deactivated_at: Time.current)

      expect(product).to have_received(:with_variant_availability_lock).at_least(:once)
      expect(product.base_variant.reload).not_to be_deactivated
    end

    it "reactivates Base when the last active real Variant is removed" do
      product = create(:product)
      variant = create(:variant, product:)

      variant.remove_or_deactivate!

      expect(product.base_variant.reload).not_to be_deactivated
    end

    it "keeps Base deactivated while another active real Variant remains" do
      product = create(:product)
      first_variant = create(:variant, product:)
      create(:variant, :with_color, product:)

      first_variant.update!(deactivated_at: Time.current)

      expect(product.base_variant.reload).to be_deactivated
    end

    it "prevents direct Base activation changes" do
      product = create(:product)
      base_variant = product.base_variant

      expect(base_variant.update(deactivated_at: Time.current)).to be false
      expect(base_variant.errors[:base]).to be_present
      expect(base_variant.reload).not_to be_deactivated
    end

    it "prevents direct Base removal" do
      base_variant = create(:product).base_variant

      expect { base_variant.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(base_variant.reload).to be_persisted
    end

    it "allows Product-owned destruction to remove Base" do
      product = create(:product)
      base_variant_id = product.base_variant.id

      product.destroy!

      expect(Variant.exists?(base_variant_id)).to be false
    end

    it "allows Product-owned destruction to remove referenced Variants and transactions" do
      product = create(:product)
      variant = create(:variant, product:)
      purchase = create(:purchase, product:, variant:)
      sale_item = create(:sale_item, product:, variant:)

      product.destroy!

      aggregate_failures do
        expect(Variant.exists?(variant.id)).to be(false)
        expect(Purchase.exists?(purchase.id)).to be(false)
        expect(SaleItem.exists?(sale_item.id)).to be(false)
      end
    end
  end

  describe "#assignable_variants" do
    it "returns the active Base when no active real Variant exists" do
      product = create(:product)

      expect(product.assignable_variants).to contain_exactly(product.base_variant)
    end

    it "returns only active real Variants when any exist" do
      product = create(:product)
      active_variant = create(:variant, product:)
      deactivated_variant = create(:variant, :with_color, product:)
      deactivated_variant.update!(deactivated_at: Time.current)

      expect(product.assignable_variants).to contain_exactly(active_variant)
    end
  end

  describe "#variant_repair_candidates" do
    it "adds same-Product deactivated real Variants with historical labels" do
      product = create(:product)
      active_variant = create(:variant, product:)
      historical_variant = create(:variant, :with_color, product:)
      historical_variant.update!(deactivated_at: Time.current)
      other_historical_variant = create(:variant)
      other_historical_variant.update!(deactivated_at: Time.current)

      candidates = product.variant_repair_candidates

      expect(candidates).to contain_exactly(active_variant, historical_variant)
      expect(historical_variant.assignment_label).to eq("#{historical_variant.title} (Historical)")
      expect(candidates).not_to include(product.base_variant, other_historical_variant)
    end
  end
end
