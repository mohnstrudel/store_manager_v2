# frozen_string_literal: true

require "rails_helper"

describe PurchaseItem do
  describe ".available_for_product_linking" do
    subject(:scope) { described_class.available_for_product_linking(product.id) }

    let(:product) { create(:product) }
    let(:sale_item) { create(:sale_item) }
    let(:paid_purchase) { create(:purchase, product:, payments_count: 1) }
    let(:unpaid_purchase) { create(:purchase, product:, payments_count: 0) }

    let!(:paid_item) { create(:purchase_item, purchase: paid_purchase, sale_item_id: nil, created_at: 2.days.ago) }
    let!(:unpaid_item) { create(:purchase_item, purchase: unpaid_purchase, sale_item_id: nil, created_at: 1.day.ago) }
    let!(:older_paid_item) { create(:purchase_item, purchase: paid_purchase, sale_item_id: nil, created_at: 3.days.ago) }
    let!(:linked_item) { create(:purchase_item, purchase: paid_purchase, sale_item: sale_item) }

    it "returns unlinked items for given product_id" do # rubocop:todo RSpec/MultipleExpectations
      expect(scope).to contain_exactly(paid_item, older_paid_item, unpaid_item)
      expect(scope).not_to include(linked_item)
    end

    it "orders by paid status (paid first), then created_at asc" do
      expect(scope.to_a).to eq([older_paid_item, paid_item, unpaid_item])
    end

    it "returns empty relation for non-existent product_id" do
      expect(described_class.available_for_product_linking(999)).to be_empty
    end
  end

  describe "#link_to_sale_item!" do
    it "links the purchase item to a sale item" do
      purchase_item = create(:purchase_item)
      sale_item = create(:sale_item)

      purchase_item.link_to_sale_item!(sale_item.id)

      expect(purchase_item.reload.sale_item_id).to eq(sale_item.id)
    end
  end
end
