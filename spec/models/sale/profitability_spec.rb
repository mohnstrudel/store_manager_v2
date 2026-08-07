# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Profitability, :aggregate_failures do
  let(:sale) do
    create(
      :sale,
      status: "pre-ordered",
      expected_revenue: BigDecimal("300"),
      received_revenue: BigDecimal("100"),
      outstanding_revenue: BigDecimal("200"),
      refunded_revenue: BigDecimal("0")
    )
  end

  before do
    product = create(:product)
    sale_item = create(:sale_item, sale:, product:, variant: nil, qty: 1)
    purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("100"))
    create(:purchase_item, :with_direct_expense, purchase:, sale_item:, shipping_cost: BigDecimal("15"), direct_expense_amount: BigDecimal("5"))
  end

  describe "#profitability" do
    it "aggregates purchase cost from linked purchase items and applies business expenses to expected revenue" do
      create(:expense_rate, rate_percent: 10)

      summary = sale.profitability

      expect(summary[:expected_revenue]).to eq(BigDecimal("300"))
      expect(summary[:received_revenue]).to eq(BigDecimal("100"))
      expect(summary[:outstanding_revenue]).to eq(BigDecimal("200"))
      expect(summary[:purchase_cost]).to eq(BigDecimal("120"))
      expect(summary[:business_expenses]).to eq(BigDecimal("30"))
      expect(summary[:realized_profit]).to eq(BigDecimal("-50"))
      expect(summary[:expected_final_profit]).to eq(BigDecimal("150"))
    end

    it "is zero business expenses without expense rates" do
      expect(sale.profitability[:business_expenses]).to eq(0)
    end

    it "names direct expenses beside the full cost of goods" do
      summary = sale.profitability

      expect(summary[:purchase_cost]).to eq(BigDecimal("120"))
      expect(summary[:direct_expenses]).to eq(BigDecimal("5"))
      expect(summary[:merchandise_cost]).to eq(BigDecimal("115"))
    end

    it "reconciles the four displayed terms to the expected final profit" do
      create(:expense_rate, rate_percent: 10)

      summary = sale.profitability
      displayed = summary[:expected_revenue] -
        summary[:merchandise_cost] -
        summary[:direct_expenses] -
        summary[:business_expenses]

      expect(displayed).to eq(BigDecimal("150"))
      expect(summary[:expected_final_profit]).to eq(BigDecimal("150"))
    end

    it "carries the projected keys as explicit nil, never absent, on the sale scope" do
      summary = sale.profitability

      expect(summary).to have_key(:projected_revenue)
      expect(summary).to have_key(:projected_business_expenses)
      expect(summary).to have_key(:projected_final_profit)
      expect(summary[:projected_revenue]).to be_nil
      expect(summary[:projected_business_expenses]).to be_nil
      expect(summary[:projected_final_profit]).to be_nil
    end
  end

  describe "#profitability_summary" do
    it "reports the sale alone when it belongs to no payment plan" do
      create(:expense_rate, rate_percent: 10)

      summary = sale.profitability_summary

      expect(summary[:scope]).to eq(:sale)
      expect(summary[:purchase_cost]).to eq(BigDecimal("120"))
      expect(summary[:expected_final_profit]).to eq(BigDecimal("150"))
    end

    it "makes no claim about a cancelled sale" do
      sale.update!(status: "cancelled")

      expect(sale.profitability_summary).to be_nil
    end

    context "with a payment plan" do
      let(:origin) do
        create(
          :sale,
          status: "pre-ordered",
          shopify_store_id: "gid://shopify/Order/900",
          expected_revenue: BigDecimal("300"),
          received_revenue: BigDecimal("300"),
          outstanding_revenue: BigDecimal("0"),
          refunded_revenue: BigDecimal("0")
        )
      end

      let(:follow_up) do
        create(
          :sale,
          status: "pre-ordered",
          shopify_store_id: "gid://shopify/Order/901",
          expected_revenue: BigDecimal("700"),
          received_revenue: BigDecimal("700"),
          outstanding_revenue: BigDecimal("0"),
          refunded_revenue: BigDecimal("0")
        )
      end

      before do
        create(:expense_rate, rate_percent: 10)

        product = create(:product)
        origin_item = create(:sale_item, sale: origin, product:, variant: nil, qty: 1)
        purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("500"))
        create(
          :purchase_item,
          :with_direct_expense,
          purchase:,
          sale_item: origin_item,
          shipping_cost: BigDecimal("50"),
          direct_expense_amount: BigDecimal("20")
        )
        # The follow-up charge carries no purchase links of its own: linkable
        # sale items skip rows carried over from the originating order.
        create(:sale_item, sale: follow_up, product:, variant: nil, qty: 1)

        create_plan(parts: [
          {sequence: 1, provider_part_id: "part-1", external_order_id: "900", amount: 300},
          {sequence: 2, provider_part_id: "part-2", external_order_id: "901", amount: 700}
        ])
      end

      it "reports the whole plan for the follow-up charge instead of its bare revenue" do
        summary = follow_up.profitability_summary

        expect(summary[:scope]).to eq(:plan)
        expect(summary[:expected_revenue]).to eq(BigDecimal("1000"))
        expect(summary[:purchase_cost]).to eq(BigDecimal("570"))
        expect(summary[:expected_final_profit]).to eq(BigDecimal("330"))
      end

      it "reports the whole plan for the originating order instead of a deposit against the full cost" do
        summary = origin.profitability_summary

        expect(summary[:scope]).to eq(:plan)
        expect(summary[:expected_revenue]).to eq(BigDecimal("1000"))
        expect(summary[:expected_final_profit]).to eq(BigDecimal("330"))
      end

      it "falls back to the sale alone when more than one plan claims it" do
        create_plan(
          external_id: "subscription-2",
          parts: [{sequence: 1, provider_part_id: "other-1", external_order_id: "901", amount: 700}]
        )

        summary = follow_up.profitability_summary

        expect(summary[:scope]).to eq(:sale)
        expect(summary[:expected_revenue]).to eq(BigDecimal("700"))
        expect(summary[:purchase_cost]).to eq(0)
        expect(summary[:projected_final_profit]).to be_nil
      end
    end
  end

  def create_plan(parts:, external_id: "subscription-1")
    SalePaymentPlan.reconcile!(
      attributes: {
        provider: "seal",
        external_id:,
        external_origin_order_id: "900",
        kind: "installments",
        status: "active",
        expected_parts: 2,
        currency: "EUR",
        synced_at: Time.current
      },
      parts: parts.map { |part| part.merge(currency: "EUR") }
    )
  end
end
