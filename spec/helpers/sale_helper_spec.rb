# frozen_string_literal: true

require "rails_helper"

RSpec.describe SaleHelper do
  describe "#sale_summary_for_warehouse" do
    it "formats the sale summary for the warehouse view" do
      sale = create(:sale)

      expect(helper.sale_summary_for_warehouse(sale)).to include(sale.customer.full_name)
    end
  end

  describe "#sale_payment_props" do
    it "does not report 100% paid when a Shopify order edit left outstanding money uncovered by expected_revenue" do
      sale = create(:sale, expected_revenue: 900, received_revenue: 900, outstanding_revenue: 100, refunded_revenue: 0)

      expect(helper.sale_payment_props(sale)[:progress]).to eq(90)
    end

    it "reports 100% paid in the common case where expected_revenue already covers received + outstanding" do
      sale = create(:sale, expected_revenue: 1000, received_revenue: 1000, outstanding_revenue: 0, refunded_revenue: 0)

      expect(helper.sale_payment_props(sale)[:progress]).to eq(100)
    end

    it "prices the bar from the same pie the progress uses, so paid + debt add up to price" do
      sale = create(:sale, total: 1060, expected_revenue: 900, received_revenue: 300, outstanding_revenue: 600)

      expect(helper.sale_payment_props(sale)).to include(progress: 33, paid: "300", price: "900", debt: "600")
    end

    it "widens the price to the pie when received + outstanding exceed expected_revenue" do
      sale = create(:sale, total: 1060, expected_revenue: 900, received_revenue: 900, outstanding_revenue: 100)

      expect(helper.sale_payment_props(sale)).to include(progress: 90, paid: "900", price: "1 000", debt: "100")
    end

    it "says the amounts are unknown when the store stated a total but no split" do
      sale = create(:sale, status: "partially-paid", expected_revenue: 991.59, received_revenue: nil, outstanding_revenue: nil)

      expect(helper.sale_payment_props(sale)).to include(
        amounts_unknown: true, progress: 0, paid: nil, price: "992", debt: nil
      )
    end

    it "does not call a stated split unknown" do
      sale = create(:sale, expected_revenue: 900, received_revenue: 300, outstanding_revenue: 600)

      expect(helper.sale_payment_props(sale)).to include(amounts_unknown: false)
    end
  end

  describe "sale item payment props" do
    it "says a sale item's amounts are unknown when the order never stated its split" do
      sale = create(:sale, status: "partially-paid", expected_revenue: 991.59, received_revenue: nil, outstanding_revenue: nil, shipping_total: 0)
      create(:sale_item, sale:, shopify_id: nil, expected_revenue: 622.59, received_revenue: nil, outstanding_revenue: nil)

      props = helper.sale_showing_props(sale.reload)[:sale_items].first[:payment]

      expect(props).to include(amounts_unknown: true, paid: nil)
    end

    it "does not call a stated sale item split unknown" do
      sale = create(:sale, expected_revenue: 900, received_revenue: 300, outstanding_revenue: 600, shipping_total: 0)
      create(:sale_item, sale:, expected_revenue: 900, received_revenue: 300, outstanding_revenue: 600)

      props = helper.sale_showing_props(sale.reload)[:sale_items].first[:payment]

      expect(props).to include(amounts_unknown: false, paid: "300", price: "900", debt: "600", progress: 33)
    end
  end

  describe "payment-plan props" do
    it "formats deposit context and projected money for the current Sale" do
      sale = create(
        :sale,
        shopify_store_id: "gid://shopify/Order/100",
        received_revenue: 320,
        refunded_revenue: 0,
        outstanding_revenue: 0
      )
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "subscription-1",
          external_origin_order_id: "100",
          kind: "deposit",
          status: "active",
          expected_parts: 1,
          deposit_percent: 30,
          projected_total: 1020,
          currency: "EUR",
          synced_at: Time.current
        },
        parts: [
          {
            provider_part_id: "subscription-1:1",
            sequence: 1,
            external_order_id: "100",
            amount: 300,
            currency: "EUR"
          }
        ]
      )

      props = helper.sale_listing_props(sale)

      expect(props[:partially_paid]).to be(false)
      expect(props[:payment_plans]).to contain_exactly(
        id: SalePaymentPlan.sole.id,
        kind: "deposit",
        expected_parts: 1,
        collected_parts: 1,
        sale_part_number: 1,
        is_origin_sale: true,
        deposit_percent: 30,
        projected_total: "1\u2009020 EUR",
        projected_collected: "320 EUR",
        origin_sale: nil,
        payments: [
          {
            sequence: 1,
            path: helper.sale_path(sale),
            identifier: sale.shopify_id,
            is_current_sale: true
          }
        ]
      )
    end

    it "marks a generic partial Sale only when no known plan exists" do
      sale = create(:sale, received_revenue: 30, outstanding_revenue: 70)

      expect(helper.sale_listing_props(sale)).to include(partially_paid: true, payment_plans: [])
    end
  end

  describe "payment-plan affiliation props" do
    it "points a follow-up payment at its originating Sale and lists every payment in the plan" do
      origin = create(:sale, shopify_name: "HSCM#1746", shopify_store_id: "gid://shopify/Order/100")
      follow_up = create(:sale, shopify_name: "HSCM#1747", shopify_store_id: "gid://shopify/Order/101")
      reconcile_two_part_plan

      props = helper.sale_listing_props(follow_up.reload)[:payment_plans].sole

      expect(props).to include(
        sale_part_number: 2,
        is_origin_sale: false,
        origin_sale: {path: helper.sale_path(origin), identifier: "HSCM#1746"}
      )
      expect(props[:payments]).to eq(
        [
          {sequence: 1, path: helper.sale_path(origin), identifier: "HSCM#1746", is_current_sale: false},
          {sequence: 2, path: helper.sale_path(follow_up), identifier: "HSCM#1747", is_current_sale: true}
        ]
      )
    end

    it "omits the origin link on the originating Sale itself" do
      origin = create(:sale, shopify_name: "HSCM#1746", shopify_store_id: "gid://shopify/Order/100")
      create(:sale, shopify_name: "HSCM#1747", shopify_store_id: "gid://shopify/Order/101")
      reconcile_two_part_plan

      props = helper.sale_listing_props(origin.reload)[:payment_plans].sole

      expect(props).to include(is_origin_sale: true, sale_part_number: 1, origin_sale: nil)
    end

    it "skips plan payments whose order has not been imported yet" do
      origin = create(:sale, shopify_name: "HSCM#1746", shopify_store_id: "gid://shopify/Order/100")
      reconcile_two_part_plan

      props = helper.sale_listing_props(origin.reload)[:payment_plans].sole

      expect(props[:payments]).to eq(
        [{sequence: 1, path: helper.sale_path(origin), identifier: "HSCM#1746", is_current_sale: true}]
      )
    end
  end

  def reconcile_two_part_plan
    SalePaymentPlan.reconcile!(
      attributes: {
        provider: "seal",
        external_id: "subscription-1",
        external_origin_order_id: "100",
        kind: "installments",
        status: "active",
        expected_parts: 4,
        synced_at: Time.current
      },
      parts: [
        {provider_part_id: "subscription-1:1", sequence: 1, external_order_id: "100"},
        {provider_part_id: "subscription-1:2", sequence: 2, external_order_id: "101"}
      ]
    )
  end
end
