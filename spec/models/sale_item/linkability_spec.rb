# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/MultipleExpectations
RSpec.describe SaleItem::Linkability do
  describe ".active" do
    let!(:active_sale_item) { create(:sale_item, sale: create(:sale, status: Sale.active_status_names.first)) }
    let!(:completed_sale_item) { create(:sale_item, sale: create(:sale, status: Sale.completed_status_names.first)) }

    it "returns sale items from active sales" do
      expect(SaleItem.active).to include(active_sale_item)
      expect(SaleItem.active).not_to include(completed_sale_item)
    end
  end

  describe ".completed" do
    let!(:active_sale_item) { create(:sale_item, sale: create(:sale, status: Sale.active_status_names.first)) }
    let!(:completed_sale_item) { create(:sale_item, sale: create(:sale, status: Sale.completed_status_names.first)) }

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
  end

  describe ".linkable_for" do
    let(:product) { create(:product) }
    let(:edition) { create(:edition, product:) }
    let(:purchase_with_edition) { create(:purchase, product:, edition:, amount: 2) }
    let(:purchase_without_edition) { create(:purchase, product:, edition: nil, amount: 2) }

    let!(:matching_edition_item) do
      create(:sale_item, product:, edition:, qty: 3, purchase_items_count: 0, sale: create(:sale, status: Sale.active_status_names.first))
    end
    let!(:matching_product_base_item) do
      create(:sale_item, product:, edition: nil, qty: 3, purchase_items_count: 0, sale: create(:sale, status: Sale.active_status_names.first))
    end
    let!(:wrong_edition_item) do
      create(:sale_item, product:, edition: create(:edition, product:), qty: 3, purchase_items_count: 0, sale: create(:sale, status: Sale.active_status_names.first))
    end

    it "filters by edition when purchase has an edition" do
      expect(SaleItem.linkable_for(purchase_with_edition)).to include(matching_edition_item)
      expect(SaleItem.linkable_for(purchase_with_edition)).not_to include(matching_product_base_item, wrong_edition_item)
    end

    it "filters by base product when purchase edition is nil" do
      expect(SaleItem.linkable_for(purchase_without_edition)).to include(matching_product_base_item)
      expect(SaleItem.linkable_for(purchase_without_edition)).not_to include(matching_edition_item, wrong_edition_item)
    end

  end

  describe ".for_edit_linking" do
    let(:product) { create(:product) }
    let(:other_product) { create(:product) }
    let(:purchase_item) { create(:purchase_item, purchase: create(:purchase, product:)) }
    let!(:same_product_active) { create(:sale_item, product:, sale: create(:sale, status: Sale.active_status_names.first)) }
    let!(:same_product_completed) { create(:sale_item, product:, sale: create(:sale, status: Sale.completed_status_names.first)) }
    let!(:other_product_active) { create(:sale_item, product: other_product, sale: create(:sale, status: Sale.active_status_names.first)) }
    let!(:cancelled_item) { create(:sale_item, product:, sale: create(:sale, status: Sale.cancelled_status_names.first)) }

    it "prioritizes sale items with the same product" do
      result = SaleItem.for_edit_linking(purchase_item)

      expect(result.first(2)).to include(same_product_active, same_product_completed)
      expect(result).to include(other_product_active)
      expect(result).not_to include(cancelled_item)
    end
  end

  describe "#resolve_sold_item" do
    let(:product) { create(:product) }

    it "returns edition when present" do
      edition = create(:edition, product:)
      sale_item = create(:sale_item, product:, edition:)

      expect(sale_item.resolve_sold_item).to eq(edition)
    end

    it "returns product when edition is missing" do
      sale_item = create(:sale_item, product:, edition: nil)

      expect(sale_item.resolve_sold_item).to eq(product)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
