# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::AssignmentIntegrity do
  subject(:integrity) { described_class.new }

  let(:product) { create(:product) }
  let(:other_product) { create(:product) }

  describe "live issue relations" do
    it "does not persist an issue table" do
      expect(
        ActiveRecord::Base.connection.data_source_exists?("variant_assignment_issues")
      ).to be(false)
    end

    it "returns broken Purchases while preserving valid historical assignments" do
      historical_variant = create(:variant, :with_version, product:)
      valid_historical = create(:purchase, product:, variant: historical_variant)
      historical_variant.update!(deactivated_at: Time.current)
      missing_variant = create(:purchase, product:)
      mismatched = create(:purchase, product:)
      missing_variant.update_columns(variant_id: nil)
      mismatched.update_columns(variant_id: other_product.base_variant.id)

      expect(integrity.broken_purchases).to contain_exactly(missing_variant, mismatched)
      expect(integrity.broken_purchases).not_to include(valid_historical)
    end

    it "returns broken SaleItems while preserving valid historical assignments" do
      historical_variant = create(:variant, :with_version, product:)
      valid_historical = create(:sale_item, product:, variant: historical_variant)
      historical_variant.update!(deactivated_at: Time.current)
      missing_variant = create(:sale_item, product:)
      mismatched = create(:sale_item, product:)
      missing_variant.update_columns(variant_id: nil)
      mismatched.update_columns(variant_id: other_product.base_variant.id)

      expect(integrity.broken_sale_items).to contain_exactly(missing_variant, mismatched)
      expect(integrity.broken_sale_items).not_to include(valid_historical)
    end

    it "returns linked PurchaseItems that disagree with their Purchase or SaleItem" do
      purchase = create(:purchase, product:, variant: product.base_variant)
      sale_item = create(:sale_item, product:, variant: product.base_variant)
      incompatible_link = create(:purchase_item, purchase:, sale_item:)
      compatible_link = create(:purchase_item, purchase:, sale_item:)

      sale_item.update_columns(
        product_id: other_product.id,
        variant_id: other_product.base_variant.id
      )
      compatible_link.update_columns(sale_item_id: nil)

      expect(integrity.incompatible_purchase_item_links).to contain_exactly(incompatible_link)
    end

    it "audits Purchase identity for every PurchaseItem, including unlinked rows" do
      purchase = create(:purchase, product:, variant: product.base_variant)
      linked = create(
        :purchase_item,
        purchase:,
        sale_item: create(:sale_item, product:, variant: product.base_variant)
      )
      unlinked = create(:purchase_item, purchase:)
      matching = create(:purchase_item, purchase:)
      linked.update_columns(product_id: other_product.id)
      unlinked.update_columns(variant_id: other_product.base_variant.id)

      expect(
        integrity.purchase_item_purchase_identity_mismatches
      ).to contain_exactly(linked, unlinked)
      expect(integrity.purchase_item_purchase_identity_mismatch?(matching.id)).to be(false)
      expect(integrity.purchase_item_purchase_identity_mismatch?(unlinked.id)).to be(true)
    end

    it "uses the live relations for counts and reason filters" do
      missing_variant = create(:purchase, product:)
      mismatch = create(:purchase, product:)
      missing_variant.update_columns(variant_id: nil)
      mismatch.update_columns(variant_id: other_product.base_variant.id)

      expect(integrity.counts).to eq(
        purchases: 2,
        sale_items: 0,
        purchase_item_links: 0
      )
      expect(
        integrity.relation_for(:purchases, reason: "missing_variant")
      ).to contain_exactly(missing_variant)
      expect(
        integrity.relation_for(:purchases, reason: "product_mismatch")
      ).to contain_exactly(mismatch)
    end

    it "returns pageable ActiveRecord relations" do
      2.times do
        purchase = create(:purchase, product:)
        purchase.update_columns(variant_id: nil)
      end

      page = integrity.relation_for(:purchases).order(:id).page(2).per(1)

      aggregate_failures do
        expect(page).to be_a(ActiveRecord::Relation)
        expect(page.current_page).to eq(2)
        expect(page.total_count).to eq(2)
        expect(page.size).to eq(1)
      end
    end
  end

  describe "record predicates" do
    it "rechecks the same live predicates by record id" do
      purchase = create(:purchase, product:)
      sale_item = create(:sale_item, product:)
      purchase.update_columns(variant_id: nil)
      sale_item.update_columns(variant_id: nil)

      expect(integrity.broken_purchase?(purchase.id)).to be(true)
      expect(integrity.broken_sale_item?(sale_item.id)).to be(true)

      purchase.update_columns(variant_id: product.base_variant.id)
      sale_item.update_columns(variant_id: product.base_variant.id)

      expect(integrity.broken_purchase?(purchase.id)).to be(false)
      expect(integrity.broken_sale_item?(sale_item.id)).to be(false)
    end
  end
end
