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

  let(:product) { create(:product) }
  let!(:sale_item) { create(:sale_item, sale:, product:, variant: nil, qty: 1) }
  let(:purchase) { create(:purchase, product:, amount: 1, item_price: BigDecimal("100")) }

  let!(:purchase_item) do
    create(
      :purchase_item,
      :with_direct_expense,
      purchase:,
      sale_item:,
      shipping_cost: BigDecimal("15"),
      direct_expense_amount: BigDecimal("5")
    )
  end

  describe "#profitability" do
    it "separates what the suppliers charged for the items from every other cost of them" do
      summary = sale.profitability

      expect(summary[:item_price_total]).to eq(BigDecimal("100"))
      expect(summary[:purchase_shipping_cost]).to eq(BigDecimal("15"))
      expect(summary[:direct_expenses]).to eq(BigDecimal("5"))
      expect(summary[:purchase_expenses]).to eq(BigDecimal("20"))
    end

    it "charges OpEx on the gross revenue and nets every cost out of it" do
      create(:expense_rate, rate_percent: 10)

      summary = sale.profitability

      expect(summary[:gross_revenue]).to eq(BigDecimal("300"))
      expect(summary[:business_expenses]).to eq(BigDecimal("30"))
      expect(summary[:net_profit]).to eq(BigDecimal("150"))
    end

    it "is zero business expenses without expense rates" do
      expect(sale.profitability[:business_expenses]).to eq(0)
    end

    it "reconciles the two stated costs and the unstated OpEx to the net profit" do
      create(:expense_rate, rate_percent: 10)

      summary = sale.profitability
      deducted = summary[:gross_revenue] -
        summary[:item_price_total] -
        summary[:purchase_expenses] -
        summary[:business_expenses]

      expect(deducted).to eq(BigDecimal("150"))
      expect(summary[:net_profit]).to eq(BigDecimal("150"))
    end

    it "keeps money sent back to the customer out of what we collected" do
      sale.update!(refunded_revenue: BigDecimal("40"))

      expect(sale.profitability[:collected_revenue]).to eq(BigDecimal("60"))
    end

    it "nets supplier money paid against customer money kept for the cash position" do
      purchase.update!(paid: BigDecimal("80"))

      summary = sale.profitability

      expect(summary[:purchase_paid]).to eq(BigDecimal("80"))
      expect(summary[:cash_position]).to eq(BigDecimal("20"))
    end

    it "claims only the linked units' share of what the supplier was paid" do
      purchase.update!(amount: 3, paid: BigDecimal("90"))

      expect(sale.profitability[:purchase_paid]).to eq(BigDecimal("30"))
    end

    it "claims no supplier money from a purchase that records no units" do
      purchase.update!(amount: 0, paid: BigDecimal("90"))

      expect(sale.profitability[:purchase_paid]).to eq(0)
    end

    it "never claims more supplier money than the purchase was paid" do
      purchase.update!(paid: BigDecimal("90"))
      create(:purchase_item, purchase:, sale_item:, shipping_cost: BigDecimal("0"), expenses: BigDecimal("0"))

      expect(sale.profitability[:purchase_paid]).to eq(BigDecimal("90"))
    end

    it "claims no cash position when the store never said how much was collected" do
      sale.update!(received_revenue: nil, outstanding_revenue: nil)

      summary = sale.profitability

      expect(summary[:collected_revenue]).to be_nil
      expect(summary[:cash_position]).to be_nil
    end

    it "states no figure the card no longer reads" do
      summary = sale.profitability

      expect(summary).not_to have_key(:merchandise_cost)
      expect(summary).not_to have_key(:purchase_cost)
      expect(summary).not_to have_key(:realized_profit)
      expect(summary).not_to have_key(:expected_final_profit)
      expect(summary).not_to have_key(:projected_revenue)
      expect(summary).not_to have_key(:projected_business_expenses)
      expect(summary).not_to have_key(:projected_final_profit)
    end
  end

  describe "#profitability_summary" do
    it "reports the sale alone when it belongs to no payment plan" do
      create(:expense_rate, rate_percent: 10)

      summary = sale.profitability_summary

      expect(summary[:scope]).to eq(:sale)
      expect(summary[:gross_revenue]).to eq(BigDecimal("300"))
      expect(summary[:item_price_total]).to eq(BigDecimal("100"))
      expect(summary[:net_profit]).to eq(BigDecimal("150"))
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

        plan_product = create(:product)
        origin_item = create(:sale_item, sale: origin, product: plan_product, variant: nil, qty: 1)
        create(
          :purchase_item,
          :with_direct_expense,
          purchase: create(:purchase, product: plan_product, amount: 1, item_price: BigDecimal("500")),
          sale_item: origin_item,
          shipping_cost: BigDecimal("50"),
          direct_expense_amount: BigDecimal("20")
        )
        # The follow-up charge carries no purchase links of its own: linkable
        # sale items skip rows carried over from the originating order.
        create(:sale_item, sale: follow_up, product: plan_product, variant: nil, qty: 1)

        create_plan(parts: [
          {sequence: 1, provider_part_id: "part-1", external_order_id: "900", amount: 300},
          {sequence: 2, provider_part_id: "part-2", external_order_id: "901", amount: 700}
        ])
      end

      it "reports the whole plan for the follow-up charge instead of its bare revenue" do
        summary = follow_up.profitability_summary

        expect(summary[:scope]).to eq(:plan)
        expect(summary[:gross_revenue]).to eq(BigDecimal("1000"))
        expect(summary[:item_price_total]).to eq(BigDecimal("500"))
        expect(summary[:purchase_expenses]).to eq(BigDecimal("70"))
        expect(summary[:net_profit]).to eq(BigDecimal("330"))
      end

      it "reports the whole plan for the originating order instead of a deposit against the full cost" do
        summary = origin.profitability_summary

        expect(summary[:scope]).to eq(:plan)
        expect(summary[:gross_revenue]).to eq(BigDecimal("1000"))
        expect(summary[:net_profit]).to eq(BigDecimal("330"))
      end

      it "claims no cash position for the deal when one charge never said what it collected" do
        follow_up.update!(received_revenue: nil, outstanding_revenue: nil)

        summary = origin.profitability_summary

        expect(summary[:collected_revenue]).to be_nil
        expect(summary[:cash_position]).to be_nil
        expect(summary[:net_profit]).to eq(BigDecimal("330"))
      end

      it "falls back to the sale alone when more than one plan claims it" do
        create_plan(
          external_id: "subscription-2",
          parts: [{sequence: 1, provider_part_id: "other-1", external_order_id: "901", amount: 700}]
        )

        summary = follow_up.profitability_summary

        expect(summary[:scope]).to eq(:sale)
        expect(summary[:gross_revenue]).to eq(BigDecimal("700"))
        expect(summary[:item_price_total]).to eq(0)
        expect(summary[:purchase_expenses]).to eq(0)
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
