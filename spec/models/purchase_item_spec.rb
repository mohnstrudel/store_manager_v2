# == Schema Information
#
# Table name: purchase_items
#
#  id                  :bigint           not null, primary key
#  expenses            :decimal(8, 2)
#  height              :integer
#  length              :integer
#  shipping_price      :decimal(8, 2)
#  tracking_number     :string
#  weight              :integer
#  width               :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  purchase_id         :bigint
#  sale_item_id        :bigint
#  shipping_company_id :bigint
#  warehouse_id        :bigint           not null
#
require "rails_helper"

describe PurchaseItem do
  describe "#name" do
    subject(:purchase_item) { create(:purchase_item) }

    it { expect(purchase_item.name).to eq(purchase_item.purchase.full_title) }
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe ".without_sale_items_by_product" do
    subject(:scope) { described_class.without_sale_items_by_product(product.id) }

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
      expect(described_class.without_sale_items_by_product(999)).to be_empty
    end
  end
end
