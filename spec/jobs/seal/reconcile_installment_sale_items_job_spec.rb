# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seal::ReconcileInstallmentSaleItemsJob do
  let(:placeholder_product) do
    create(:product, shopify_id: Product::SEAL_INSTALLMENT_PLACEHOLDER_SHOPIFY_ID, non_catalog: true)
  end

  def create_plan(external_origin_order_id:, external_id: "subscription-1")
    SalePaymentPlan.reconcile!(
      attributes: {
        provider: "seal",
        external_id:,
        external_origin_order_id:,
        kind: "installments",
        status: "active",
        expected_parts: 2,
        synced_at: Time.current
      },
      parts: [
        {sequence: 1, provider_part_id: "#{external_id}-origin", external_order_id: external_origin_order_id},
        {sequence: 2, provider_part_id: "#{external_id}-attempt-1", external_order_id: "#{external_origin_order_id}1"}
      ]
    )
  end

  def build_deal(order_id:, subscription_id:)
    origin_sale = create(:sale, shopify_store_id: order_id)
    follow_up_sale = create(:sale, shopify_store_id: "#{order_id}1")
    real_product = create(:product)
    origin_item = create(:sale_item, sale: origin_sale, product: real_product)
    payment_item = create(:sale_item, sale: follow_up_sale, product: placeholder_product)
    create_plan(external_origin_order_id: order_id, external_id: subscription_id)

    {origin_item:, payment_item:, real_product:}
  end

  describe "full mode" do
    it "reconciles every Seal plan's follow-up sales" do
      first = build_deal(order_id: "100", subscription_id: "subscription-1")
      second = build_deal(order_id: "200", subscription_id: "subscription-2")

      described_class.perform_now

      expect(first[:payment_item].reload).to have_attributes(product: first[:real_product], origin_sale_item: first[:origin_item])
      expect(second[:payment_item].reload).to have_attributes(product: second[:real_product], origin_sale_item: second[:origin_item])
    end

    it "leaves a Shopify payment_terms plan's items untouched" do
      sale = create(:sale, shopify_store_id: "300")
      item = create(:sale_item, sale:, product: create(:product))
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "shopify",
          external_id: "terms-1",
          external_origin_order_id: "300",
          kind: "payment_terms",
          status: "active",
          expected_parts: 1,
          synced_at: Time.current
        },
        parts: [{sequence: 1, provider_part_id: "sched-1", external_order_id: "300"}]
      )

      described_class.perform_now

      expect(item.reload).to have_attributes(product: item.product, origin_sale_item: nil)
    end

    it "converges without change across repeated runs" do
      deal = build_deal(order_id: "400", subscription_id: "subscription-3")
      described_class.perform_now

      expect { described_class.perform_now }.not_to change(SaleItem, :count)
      expect(deal[:payment_item].reload).to have_attributes(product: deal[:real_product], origin_sale_item: deal[:origin_item])
    end
  end

  describe "single-sale mode" do
    it "reconciles only the plan linked to the given sale, leaving other plans untouched" do
      target = build_deal(order_id: "500", subscription_id: "subscription-4")
      other = build_deal(order_id: "600", subscription_id: "subscription-5")

      described_class.perform_now(sale_id: target[:payment_item].sale_id)

      expect(target[:payment_item].reload).to have_attributes(product: target[:real_product], origin_sale_item: target[:origin_item])
      expect(other[:payment_item].reload).to have_attributes(product: placeholder_product, origin_sale_item: nil)
    end

    it "reconciles every follow-up when scoped to the origin sale" do
      deal = build_deal(order_id: "700", subscription_id: "subscription-6")

      described_class.perform_now(sale_id: deal[:origin_item].sale_id)

      expect(deal[:payment_item].reload).to have_attributes(product: deal[:real_product], origin_sale_item: deal[:origin_item])
    end

    it "is a no-op when the sale is not linked to any persisted plan" do
      unrelated_sale = create(:sale)

      expect { described_class.perform_now(sale_id: unrelated_sale.id) }.not_to change(SaleItem, :count)
    end
  end

  it "constructs no Shopify or Seal client" do
    build_deal(order_id: "800", subscription_id: "subscription-7")
    expect(Shopify::Api::Client).not_to receive(:new)
    expect(Seal::Api::Client).not_to receive(:new)

    described_class.perform_now
  end
end
