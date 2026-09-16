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

  describe "sale-show item price" do
    it "renders the plan's projected merchandise as Price while preserving Sale Total" do
      sale = create(:sale, shopify_store_id: "gid://shopify/Order/106", shipping_total: BigDecimal("22.90"), total: BigDecimal("87.29"), expected_revenue: BigDecimal("87.29"), received_revenue: 0, outstanding_revenue: BigDecimal("87.29"))
      create(:sale_item, sale:, expected_revenue: BigDecimal("87.29"), received_revenue: 0, outstanding_revenue: BigDecimal("87.29"))
      reconcile_installment_plan(external_id: "sub-origin-2", order_id: "106", projected_total: BigDecimal("538.06"))

      props = helper.sale_showing_props(sale.reload)

      expect(props[:sale_items].first[:price]).to eq("515")
      expect(props[:total]).to eq("87")
    end

    it "falls back to the order price without an eligible plan" do
      sale = create(:sale, expected_revenue: 900, received_revenue: 300, outstanding_revenue: 600, shipping_total: 0)
      create(:sale_item, sale:, expected_revenue: 900, received_revenue: 300, outstanding_revenue: 600)

      price = helper.sale_showing_props(sale.reload)[:sale_items].first[:price]

      expect(price).to eq("900")
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
          synced_at: Time.current
        },
        parts: [
          {
            provider_part_id: "subscription-1:1",
            sequence: 1,
            external_order_id: "100",
            amount: 300
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
        projected_total: "1\u2009020",
        projected_collected: "320",
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

  describe "#sale_settlement_props" do
    it "passes through the normalized settlement status" do
      sale = create(:sale, settlement_status: "paid")

      expect(helper.sale_settlement_props(sale)[:settlement_status]).to eq("paid")
    end

    it "reports no status or progress for an economically excluded sale" do
      sale = create(:sale, settlement_status: "not_fully_paid", status: "cancelled")

      expect(helper.sale_settlement_props(sale)).to eq(settlement_status: nil, payment_progress: nil)
    end

    it "reports no progress for an unknown settlement" do
      sale = create(:sale, settlement_status: "unknown")

      expect(helper.sale_settlement_props(sale)[:payment_progress]).to be_nil
    end
  end

  describe "#sale_settlement_props payment_progress" do
    it "computes amount progress from known received and outstanding revenue" do
      sale = create(:sale, settlement_status: "not_fully_paid", expected_revenue: 1000, received_revenue: 300, outstanding_revenue: 700)

      expect(helper.sale_settlement_props(sale)[:payment_progress]).to include(
        source: "amount", percent: 30, paid: "$300", total: "$1,000", remaining: "$700"
      )
    end

    it "reports zero percent instead of nil when nothing has been paid yet" do
      sale = create(:sale, settlement_status: "not_fully_paid", expected_revenue: 1000, received_revenue: 0, outstanding_revenue: 1000)

      expect(helper.sale_settlement_props(sale)[:payment_progress]).to include(
        source: "amount", percent: 0, paid: "$0", total: "$1,000", remaining: "$1,000"
      )
    end

    it "reports 100 percent and no remaining claim once fully paid" do
      sale = create(:sale, settlement_status: "paid", expected_revenue: 1000, received_revenue: 1000, outstanding_revenue: 0)

      expect(helper.sale_settlement_props(sale)[:payment_progress]).to include(source: "amount", percent: 100, remaining: nil)
    end

    it "falls back to amount progress when the plan carries no known projected total" do
      sale = create(:sale, settlement_status: "not_fully_paid", shopify_store_id: "gid://shopify/Order/500", expected_revenue: 1000, received_revenue: 300, outstanding_revenue: 700)
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "shopify",
          external_id: "terms-500",
          external_origin_order_id: "500",
          kind: "payment_terms",
          status: "active",
          expected_parts: 2,
          projected_total: nil,
          synced_at: Time.current
        },
        parts: [{provider_part_id: "terms-500:1", sequence: 1, external_order_id: "500"}]
      )

      expect(helper.sale_settlement_props(sale.reload)[:payment_progress]).to include(source: "amount", percent: 30)
    end

    it "shows a Seal deposit's amount progress against its projected total, never a part count" do
      sale = create(:sale, settlement_status: "not_fully_paid", shopify_store_id: "gid://shopify/Order/100", received_revenue: 420, refunded_revenue: 0, outstanding_revenue: 0)
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "subscription-deposit",
          external_origin_order_id: "100",
          kind: "deposit",
          status: "active",
          expected_parts: 1,
          deposit_percent: 30,
          projected_total: 1400,
          synced_at: Time.current
        },
        parts: [{provider_part_id: "subscription-deposit:1", sequence: 1, external_order_id: "100", amount: 420}]
      )

      progress = helper.sale_settlement_props(sale.reload)[:payment_progress]

      expect(progress).to include(
        source: "plan_deposit", percent: 30, paid: "$420", total: "$1,400", remaining: "$980",
        completed_parts: nil, expected_parts: nil, sale_part_number: nil
      )
    end

    it "falls back to sale-amount progress when more than one plan claims the sale" do
      sale = create(:sale, settlement_status: "not_fully_paid", shopify_store_id: "gid://shopify/Order/200", expected_revenue: 1000, received_revenue: 300, outstanding_revenue: 700, refunded_revenue: 0)
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "subscription-ambiguous-a",
          external_origin_order_id: "200",
          kind: "deposit",
          status: "active",
          expected_parts: 1,
          deposit_percent: 30,
          projected_total: 1400,
          synced_at: Time.current
        },
        parts: [{provider_part_id: "subscription-ambiguous-a:1", sequence: 1, external_order_id: "200", amount: 420}]
      )
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "subscription-ambiguous-b",
          external_origin_order_id: nil,
          kind: "installments",
          status: "active",
          expected_parts: 2,
          projected_total: 900,
          synced_at: Time.current
        },
        parts: [{provider_part_id: "subscription-ambiguous-b:1", sequence: 1, external_order_id: "200"}]
      )

      progress = helper.sale_settlement_props(sale.reload)[:payment_progress]

      expect(progress).to include(source: "amount", percent: 30, paid: "$300", total: "$1,000", remaining: "$700")
    end

    it "shows completed and expected parts for a real installment schedule" do
      sale = create(:sale, settlement_status: "not_fully_paid", shopify_store_id: "gid://shopify/Order/300", received_revenue: 300, refunded_revenue: 0)
      create(:sale, shopify_store_id: "gid://shopify/Order/301", received_revenue: 200, refunded_revenue: 0)
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "subscription-schedule",
          external_origin_order_id: "300",
          kind: "installments",
          status: "active",
          expected_parts: 4,
          projected_total: 1000,
          synced_at: Time.current
        },
        parts: [
          {provider_part_id: "subscription-schedule:1", sequence: 1, external_order_id: "300"},
          {provider_part_id: "subscription-schedule:2", sequence: 2, external_order_id: "301"}
        ]
      )

      progress = helper.sale_settlement_props(sale.reload)[:payment_progress]

      expect(progress).to include(
        source: "plan_schedule", percent: 50, paid: "$500", total: "$1,000", remaining: "$500",
        completed_parts: 2, expected_parts: 4, sale_part_number: 1
      )
    end

    it "computes the amount percentage independently of the parts fraction" do
      sale = create(:sale, settlement_status: "not_fully_paid", shopify_store_id: "gid://shopify/Order/400", received_revenue: 500, refunded_revenue: 0)
      create(:sale, shopify_store_id: "gid://shopify/Order/401", received_revenue: 300, refunded_revenue: 0)
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "subscription-unequal",
          external_origin_order_id: "400",
          kind: "installments",
          status: "active",
          expected_parts: 4,
          projected_total: 1000,
          synced_at: Time.current
        },
        parts: [
          {provider_part_id: "subscription-unequal:1", sequence: 1, external_order_id: "400"},
          {provider_part_id: "subscription-unequal:2", sequence: 2, external_order_id: "401"}
        ]
      )

      progress = helper.sale_settlement_props(sale.reload)[:payment_progress]

      expect(progress).to include(completed_parts: 2, expected_parts: 4, percent: 80)
    end

    it "shows a Woo verified deposit's collected amount and order total, with no percentage or remaining" do
      sale = create(:sale, settlement_status: "not_fully_paid", expected_revenue: 1145, received_revenue: 196, outstanding_revenue: nil)

      expect(helper.sale_settlement_props(sale)[:payment_progress]).to include(
        source: "woo_deposit", paid: "$196", total: "$1,145", percent: nil, remaining: nil
      )
    end

    it "reports the order total when Woo payment amounts are unavailable" do
      sale = create(:sale, settlement_status: "not_fully_paid", expected_revenue: 1145, received_revenue: nil, outstanding_revenue: nil)

      expect(helper.sale_settlement_props(sale)[:payment_progress]).to include(
        source: "woo_unavailable", paid: nil, total: "$1,145"
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

  def reconcile_installment_plan(external_id:, order_id:, projected_total:)
    SalePaymentPlan.reconcile!(
      attributes: {
        provider: "seal",
        external_id:,
        external_origin_order_id: order_id,
        kind: "installments",
        status: "active",
        expected_parts: 4,
        projected_total:,
        synced_at: Time.current
      },
      parts: []
    )
  end
end
