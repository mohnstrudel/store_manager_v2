# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/MultipleExpectations
RSpec.describe SaleItem::Linkable do
  describe ".active" do
    let!(:active_sale_item) { create(:sale_item, sale: create(:sale, status: Sale::ACTIVE_STATUSES.first)) }
    let!(:completed_sale_item) { create(:sale_item, sale: create(:sale, status: Sale::COMPLETED_STATUSES.first)) }

    it "returns sale items from active sales" do
      expect(SaleItem.active).to include(active_sale_item)
      expect(SaleItem.active).not_to include(completed_sale_item)
    end
  end

  describe ".completed" do
    let!(:active_sale_item) { create(:sale_item, sale: create(:sale, status: Sale::ACTIVE_STATUSES.first)) }
    let!(:completed_sale_item) { create(:sale_item, sale: create(:sale, status: Sale::COMPLETED_STATUSES.first)) }

    it "returns sale items from completed sales" do
      expect(SaleItem.completed).to include(completed_sale_item)
      expect(SaleItem.completed).not_to include(active_sale_item)
    end
  end

  describe ".linkable" do
    let!(:linkable_sale_item) { create(:sale_item, qty: 2, purchase_items_count: 1) }
    let!(:full_sale_item) { create(:sale_item, qty: 1, purchase_items_count: 1) }

    it "returns sale items that still have unlinked quantity" do
      expect(SaleItem.linkable).to include(linkable_sale_item)
      expect(SaleItem.linkable).not_to include(full_sale_item)
    end

    it "compares quantity with the cached count at every boundary" do
      unlinked = create(:sale_item, qty: 1, purchase_items_count: 0)
      over_linked = create(:sale_item, qty: 1, purchase_items_count: 2)
      zero_qty = create(:sale_item, qty: 0, purchase_items_count: 0)
      nil_qty = create(:sale_item, qty: 1, purchase_items_count: 0).tap { it.update_columns(qty: nil) }

      expect(SaleItem.linkable).to contain_exactly(linkable_sale_item, unlinked)
      expect(SaleItem.where(id: [over_linked, zero_qty, nil_qty]).linkable).to be_empty
    end
  end

  describe ".short_of_purchases" do
    def link_purchase_items(sale_item, count)
      purchase = create(:purchase, product: sale_item.product, amount: count)
      create_list(:purchase_item, count, purchase:, sale_item:)
    end

    it "compares quantity with live purchase links at every boundary" do
      unlinked = create(:sale_item, qty: 1)
      short = create(:sale_item, qty: 2).tap { link_purchase_items(it, 1) }
      covered = create(:sale_item, qty: 1).tap { link_purchase_items(it, 1) }
      over_linked = create(:sale_item, qty: 1).tap { link_purchase_items(it, 2) }
      zero_qty = create(:sale_item, qty: 0)
      nil_qty = create(:sale_item, qty: 1).tap { it.update_columns(qty: nil) }

      expect(SaleItem.short_of_purchases).to contain_exactly(unlinked, short)
      expect(SaleItem.where(id: [covered, over_linked, zero_qty, nil_qty]).short_of_purchases).to be_empty
    end

    it "ignores a stale cached count" do
      cache_says_covered = create(:sale_item, qty: 1).tap { it.update_columns(purchase_items_count: 1) }
      cache_says_short = create(:sale_item, qty: 1).tap { link_purchase_items(it, 1) }
      cache_says_short.update_columns(purchase_items_count: 0)

      expect(SaleItem.short_of_purchases).to contain_exactly(cache_says_covered)
    end

    it "selects nothing when no sale item exists" do
      expect(SaleItem.short_of_purchases).to be_empty
    end
  end

  describe ".linkable_for" do
    let(:variant_product) { create(:product) }
    let(:base_product) { create(:product) }
    let(:variant) { create(:variant, product: variant_product) }
    let(:purchase_with_variant) { create(:purchase, product: variant_product, variant:, amount: 2) }
    let(:purchase_with_base) { create(:purchase, product: base_product, variant: nil, amount: 2) }

    let!(:matching_variant_item) do
      create(:sale_item, product: variant_product, variant:, qty: 3, purchase_items_count: 0, sale: create(:sale, status: Sale::ACTIVE_STATUSES.first))
    end
    let!(:matching_base_item) do
      create(:sale_item, product: base_product, variant: nil, qty: 3, purchase_items_count: 0, sale: create(:sale, status: Sale::ACTIVE_STATUSES.first))
    end
    let!(:wrong_variant_item) do
      create(:sale_item, product: variant_product, variant: create(:variant, product: variant_product), qty: 3, purchase_items_count: 0, sale: create(:sale, status: Sale::ACTIVE_STATUSES.first))
    end

    it "filters by variant when purchase has a variant" do
      expect(SaleItem.linkable_for(purchase_with_variant)).to include(matching_variant_item)
      expect(SaleItem.linkable_for(purchase_with_variant)).not_to include(matching_base_item, wrong_variant_item)
    end

    it "filters by the normalized Base Variant for a Base-only Product" do
      expect(SaleItem.linkable_for(purchase_with_base)).to include(matching_base_item)
      expect(SaleItem.linkable_for(purchase_with_base)).not_to include(matching_variant_item, wrong_variant_item)
    end
  end

  describe ".for_edit_linking" do
    let(:product) { create(:product) }
    let(:other_product) { create(:product) }
    let!(:purchase_item) { create(:purchase_item, purchase: create(:purchase, product:)) }
    let!(:same_product_active) { create(:sale_item, product:, sale: create(:sale, status: Sale::ACTIVE_STATUSES.first)) }
    let!(:same_product_cancelled) { create(:sale_item, product:, sale: create(:sale, status: Sale::CANCELLED_STATUSES.first)) }
    let!(:other_product_item) { create(:sale_item, product: other_product, sale: create(:sale, status: Sale::ACTIVE_STATUSES.first)) }
    let!(:fully_linked_item) { create(:sale_item, product:, qty: 1, purchase_items_count: 1, sale: create(:sale, status: Sale::ACTIVE_STATUSES.first)) }
    let!(:wrong_variant_item) do
      variant = create(:variant, :with_version, product:)
      create(:sale_item, product:, variant:, sale: create(:sale, status: Sale::ACTIVE_STATUSES.first))
    end

    it "returns linkable sale items for the same product regardless of status" do
      result = SaleItem.for_edit_linking(purchase_item)

      expect(result).to include(same_product_active, same_product_cancelled)
      expect(result).not_to include(wrong_variant_item, other_product_item, fully_linked_item)
    end

    it "always includes the currently linked sale item even if at capacity" do
      fully_linked_item.update_column(:purchase_items_count, 0)
      PurchaseItem.link_exact(
        assignments: [{purchase_item:, sale_item: fully_linked_item}]
      )
      purchase_item.reload

      result = SaleItem.for_edit_linking(purchase_item)

      expect(result).to include(fully_linked_item)
    end
  end

  describe ".for_linking_table" do
    it "shows only exact Product and Variant matches plus the current link" do
      product = create(:product)
      purchase_item = create(:purchase_item, purchase: create(:purchase, product:))
      exact = create(:sale_item, product:, variant: purchase_item.variant)
      wrong_variant = create(:sale_item, product:, variant: create(:variant, :with_version, product:))

      result = SaleItem.for_linking_table(purchase_item)

      expect(result).to include(exact)
      expect(result).not_to include(wrong_variant)
    end
  end

  describe "#resolve_sold_item" do
    let(:product) { create(:product) }

    it "returns variant when present" do
      variant = create(:variant, product:)
      sale_item = create(:sale_item, product:, variant:)

      expect(sale_item.resolve_sold_item).to eq(variant)
    end

    it "returns Base when Variant input is omitted for a Base-only Product" do
      sale_item = create(:sale_item, product:, variant: nil)

      expect(sale_item.resolve_sold_item).to eq(product.base_variant)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
