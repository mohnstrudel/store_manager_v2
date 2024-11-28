# == Schema Information
#
# Table name: product_sales
#
#  id           :bigint           not null, primary key
#  price        :decimal(8, 2)
#  qty          :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  product_id   :bigint           not null
#  sale_id      :bigint           not null
#  variation_id :bigint
#  woo_id       :string
#
require "rails_helper"

RSpec.describe ProductSale, type: :model do
  describe "#link_purchased_products" do
    let(:product) { create(:product) }
    let(:sale) { create(:sale) }
    let(:product_sale) { build(:product_sale, product:, sale:, qty: 2) }

    before do
      create_list(:purchased_product, 3, product:, product_sale: nil)
    end

    it "connects purchased products when the sale has an active status" do
      active_sale = create(:sale, status: Sale.active_status_names.sample)
      active_product_sale = build(:product_sale, product:, sale: active_sale, qty: 2)

      expect {
        active_product_sale.save
      }.to change {
        PurchasedProduct
          .where(product_sale_id: active_product_sale.id)
          .where.not(product_sale_id: nil)
          .count
      }.from(0).to(2)
    end

    it "does not connect purchased products when the sale has an inactive status" do
      inactive_sale = create(:sale, status: (Sale.status_names - Sale.active_status_names).sample)
      inactive_product_sale = build(:product_sale, product:, sale: inactive_sale, qty: 2)

      expect {
        inactive_product_sale.save
      }.not_to change {
        PurchasedProduct
          .where(product_sale_id: inactive_product_sale.id)
          .where.not(product_sale_id: nil)
          .count
      }
    end

    it "connects purchased products in the order they were created" do
      product_sale.save
      connected_products = PurchasedProduct
        .where(product_sale:)
        .order(:created_at)
      expect(connected_products.first.created_at).to be < connected_products.last.created_at
    end

    it "dispatches notifications for linked purchased products" do
      notification_class = class_spy(Notification)
      allow(notification_class).to receive(:event_types)
        .and_return({product_purchased: 0})
      stub_const("Notification", notification_class)

      product_sale.save

      linked_purchased_products = PurchasedProduct.where(product_sale:)

      expect(notification_class).to have_received(:dispatch)
        .with(
          event: 0,
          context: hash_including(purchased_product_id: kind_of(Integer))
        )
        .exactly(linked_purchased_products.count).times
    end
  end
end
