# == Schema Information
#
# Table name: purchased_products
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
#  product_sale_id     :bigint
#  purchase_id         :bigint
#  shipping_company_id :bigint
#  warehouse_id        :bigint           not null
#
require "rails_helper"

describe PurchasedProduct do
  describe ".bulk_move_to_warehouse" do
    let(:from_warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }
    let(:purchased_products) { create_list(:purchased_product, 3, warehouse: from_warehouse) }
    let(:notification_service) {
      class_spy(Notification).tap do |spy|
        allow(spy).to receive(:event_types).and_return({warehouse_changed: 1})
      end
    }

    before do
      stub_const("Notification", notification_service)
    end

    it "moves all products to the destination warehouse" do
      moved_count = described_class.bulk_move_to_warehouse(purchased_products.map(&:id), to_warehouse.id)

      expect(moved_count).to eq(3)
      purchased_products.each do |product|
        expect(product.reload.warehouse_id).to eq(to_warehouse.id)
      end
    end

    it "dispatches notifications for moved products" do
      described_class.bulk_move_to_warehouse(purchased_products.map(&:id), to_warehouse.id)

      expect(notification_service).to have_received(:dispatch).with(
        event: 1,
        context: {
          purchased_product_ids: purchased_products.map(&:id),
          from_id: from_warehouse.id,
          to_id: to_warehouse.id
        }
      )
    end

    it "returns 0 and doesn't dispatch notifications when no products are moved" do
      moved_count = described_class.bulk_move_to_warehouse([], to_warehouse.id)

      expect(moved_count).to eq(0)
      expect(notification_service).not_to have_received(:dispatch)
    end
  end

  describe "#name" do
    subject(:purchased_product) { create(:purchased_product) }

    it { expect(purchased_product.name).to eq(purchased_product.purchase.full_title) }
  end
end
