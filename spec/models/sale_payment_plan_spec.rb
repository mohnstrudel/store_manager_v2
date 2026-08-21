# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: sale_payment_plans
#
#  id                       :bigint           not null, primary key
#  currency                 :string
#  deposit_percent          :decimal(5, 2)
#  expected_parts           :integer          not null
#  kind                     :string           not null
#  next_due_at              :datetime
#  projected_total          :decimal(12, 2)
#  provider                 :string           not null
#  status                   :string
#  synced_at                :datetime         not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  external_id              :string           not null
#  external_origin_order_id :string
#  origin_sale_id           :bigint
#
RSpec.describe SalePaymentPlan do
  describe ".reconcile!" do
    it "links an existing origin and parts through normalized Shopify order IDs" do
      origin = create(:sale, shopify_store_id: "gid://shopify/Order/100")
      installment = create(:sale, shopify_store_id: "gid://shopify/Order/101")

      plan = described_class.reconcile!(
        attributes: plan_attributes(external_origin_order_id: "100"),
        parts: [
          part_attributes(sequence: 1, provider_part_id: "origin", external_order_id: "100"),
          part_attributes(sequence: 2, provider_part_id: "attempt-1", external_order_id: "101")
        ]
      )

      expect(plan.origin_sale).to eq(origin)
      expect(plan.parts.order(:sequence).map(&:sale)).to eq([origin, installment])
    end

    it "is idempotent and supports multiple plans for the same origin Sale" do
      origin = create(:sale, shopify_store_id: "gid://shopify/Order/100")
      attributes = plan_attributes(external_origin_order_id: "100")
      parts = [part_attributes(sequence: 1, provider_part_id: "origin", external_order_id: "100")]

      expect {
        2.times { described_class.reconcile!(attributes:, parts:) }
        described_class.reconcile!(
          attributes: attributes.merge(external_id: "subscription-2"),
          parts:
        )
      }.to change(described_class, :count).by(2)
        .and change(SalePaymentPart, :count).by(2)

      expect(origin.reload.origin_payment_plans.count).to eq(2)
      expect(origin.sale_payment_parts.count).to eq(2)
    end

    it "links plans and parts when the Sale is imported after the provider snapshot" do
      plan = described_class.reconcile!(
        attributes: plan_attributes(external_origin_order_id: "100"),
        parts: [
          part_attributes(sequence: 1, provider_part_id: "origin", external_order_id: "100"),
          part_attributes(sequence: 2, provider_part_id: "attempt-1", external_order_id: "101")
        ]
      )
      origin = create(:sale, shopify_store_id: "gid://shopify/Order/100")
      installment = create(:sale, shopify_store_id: "gid://shopify/Order/101")

      described_class.reconcile_sale!(origin)
      described_class.reconcile_sale!(installment)

      expect(plan.reload.origin_sale).to eq(origin)
      expect(plan.parts.order(:sequence).map(&:sale)).to eq([origin, installment])
    end

    it "prunes obsolete unlinked parts and preserves linked history as inactive" do
      linked_sale = create(:sale, shopify_store_id: "gid://shopify/Order/101")
      plan = described_class.reconcile!(
        attributes: plan_attributes,
        parts: [
          part_attributes(sequence: 1, provider_part_id: "part-1"),
          part_attributes(sequence: 2, provider_part_id: "part-2", external_order_id: "101"),
          part_attributes(sequence: 3, provider_part_id: "part-3")
        ]
      )

      described_class.reconcile!(
        attributes: plan_attributes(expected_parts: 1),
        parts: [part_attributes(sequence: 1, provider_part_id: "part-1")]
      )

      expect(plan.parts.reload.order(:sequence).pluck(:sequence, :active)).to eq([[1, true], [2, false]])
      expect(plan.parts.find_by(sequence: 2).sale).to eq(linked_sale)
    end
  end

  describe "derived payment state" do
    it "counts only settled SEAL parts with positive net collected money" do
      collected = create(
        :sale,
        shopify_store_id: "gid://shopify/Order/100",
        received_revenue: 100,
        refunded_revenue: 0,
        outstanding_revenue: 0
      )
      refunded = create(
        :sale,
        shopify_store_id: "gid://shopify/Order/101",
        received_revenue: 100,
        refunded_revenue: 100,
        outstanding_revenue: 0
      )
      outstanding = create(
        :sale,
        shopify_store_id: "gid://shopify/Order/102",
        received_revenue: 50,
        refunded_revenue: 0,
        outstanding_revenue: 50
      )
      plan = described_class.reconcile!(
        attributes: plan_attributes,
        parts: [
          part_attributes(sequence: 1, provider_part_id: "part-1", external_order_id: "100"),
          part_attributes(sequence: 2, provider_part_id: "part-2", external_order_id: "101"),
          part_attributes(sequence: 3, provider_part_id: "part-3", external_order_id: "102")
        ]
      )

      expect(plan.collected_parts).to eq(1)
      expect(plan.parts.order(:sequence).map(&:sale)).to eq([collected, refunded, outstanding])
    end

    it "uses Shopify schedule completion while retaining Shopify money authority" do
      sale = create(
        :sale,
        shopify_store_id: "gid://shopify/Order/100",
        received_revenue: 500,
        refunded_revenue: 0
      )
      plan = described_class.reconcile!(
        attributes: plan_attributes(provider: "shopify", external_id: "terms-1"),
        parts: [
          part_attributes(sequence: 1, provider_part_id: "schedule-1", provider_completed_at: 1.day.ago),
          part_attributes(sequence: 2, provider_part_id: "schedule-2")
        ]
      )
      plan.update!(origin_sale: sale)

      expect(plan.collected_parts).to eq(1)

      sale.update!(refunded_revenue: 500)

      expect(plan.reload.collected_parts).to eq(0)
    end

    it "projects deposit merchandise before adding shipping once" do
      expect(
        described_class.projected_deposit_total(
          deposit_merchandise_amount: 300,
          deposit_percent: 30,
          shipping_amount: 40
        )
      ).to eq(BigDecimal("1040"))
    end

    it "subtracts unique linked Sale cash from the projected remainder" do
      sale = create(
        :sale,
        shopify_store_id: "gid://shopify/Order/100",
        received_revenue: 340,
        refunded_revenue: 0,
        outstanding_revenue: 0
      )
      plan = described_class.reconcile!(
        attributes: plan_attributes(
          kind: "deposit",
          expected_parts: 1,
          deposit_percent: 30,
          projected_total: 1040
        ),
        parts: [part_attributes(sequence: 1, provider_part_id: "origin", external_order_id: "100")]
      )

      expect(plan.origin_sale).to eq(sale)
      expect(plan.projected_remainder).to eq(BigDecimal("700"))
    end
  end

  describe "#profitability" do
    it "aggregates every sale in the plan so cost and revenue meet in one place" do
      create(:expense_rate, rate_percent: 10)
      product = create(:product)
      origin = create(
        :sale,
        status: "pre-ordered",
        shopify_store_id: "gid://shopify/Order/100",
        expected_revenue: 300,
        received_revenue: 300,
        outstanding_revenue: 0,
        refunded_revenue: 0
      )
      follow_up = create(
        :sale,
        status: "pre-ordered",
        shopify_store_id: "gid://shopify/Order/101",
        expected_revenue: 700,
        received_revenue: 700,
        outstanding_revenue: 0,
        refunded_revenue: 0
      )
      origin_item = create(:sale_item, sale: origin, product:, variant: nil, qty: 1)
      create(:sale_item, sale: follow_up, product:, variant: nil, qty: 1)
      create(
        :purchase_item,
        :with_direct_expense,
        purchase: create(:purchase, product:, amount: 1, item_price: BigDecimal("500")),
        sale_item: origin_item,
        shipping_cost: BigDecimal("50"),
        direct_expense_amount: BigDecimal("20")
      )

      plan = described_class.reconcile!(
        attributes: plan_attributes(expected_parts: 2),
        parts: [
          part_attributes(sequence: 1, provider_part_id: "part-1", external_order_id: "100", amount: 300),
          part_attributes(sequence: 2, provider_part_id: "part-2", external_order_id: "101", amount: 700)
        ]
      )

      summary = plan.profitability

      expect(summary[:gross_revenue]).to eq(BigDecimal("1000"))
      expect(summary[:collected_revenue]).to eq(BigDecimal("1000"))
      expect(summary[:item_price_total]).to eq(BigDecimal("500"))
      expect(summary[:purchase_shipping_cost]).to eq(BigDecimal("50"))
      expect(summary[:direct_expenses]).to eq(BigDecimal("20"))
      expect(summary[:purchase_expenses]).to eq(BigDecimal("70"))
      expect(summary[:business_expenses]).to eq(BigDecimal("100"))
      expect(summary[:net_profit]).to eq(BigDecimal("330"))
      expect(summary[:cash_position]).to eq(BigDecimal("1000"))
    end

    it "measures the whole contract value against the whole cost, not the deposit alone" do
      # Worked example from the ticket: a 30% deposit on a 1 020 deal, the
      # remaining 70% not yet raised as a Sale, at a 15% OpEx rate.
      create(:expense_rate, rate_percent: 15)
      product = create(:product)
      origin = create(
        :sale,
        status: "pre-ordered",
        shopify_store_id: "gid://shopify/Order/200",
        expected_revenue: 300,
        received_revenue: 300,
        outstanding_revenue: 0,
        refunded_revenue: 0
      )
      origin_item = create(:sale_item, sale: origin, product:, variant: nil, qty: 1)
      create(
        :purchase_item,
        purchase: create(:purchase, product:, amount: 1, item_price: BigDecimal("700")),
        sale_item: origin_item,
        shipping_cost: BigDecimal("0")
      )

      plan = described_class.reconcile!(
        attributes: plan_attributes(
          kind: "deposit",
          expected_parts: 1,
          deposit_percent: 30,
          projected_total: 1020
        ),
        parts: [part_attributes(sequence: 1, provider_part_id: "origin", external_order_id: "200", amount: 300)]
      )

      summary = plan.profitability

      # The deal, not the one raised charge: OpEx follows the contract value
      # too, so 1 020 is not measured against the 45.00 charged on 300.
      expect(summary[:gross_revenue]).to eq(BigDecimal("1020"))
      expect(summary[:item_price_total]).to eq(BigDecimal("700"))
      expect(summary[:purchase_expenses]).to eq(0)
      expect(summary[:business_expenses]).to eq(BigDecimal("153"))
      expect(summary[:net_profit]).to eq(BigDecimal("167"))

      # Cash is what moved, never what the contract promises.
      expect(summary[:collected_revenue]).to eq(BigDecimal("300"))
      expect(summary[:cash_position]).to eq(BigDecimal("300"))
    end
  end

  def plan_attributes(overrides = {})
    {
      provider: "seal",
      external_id: "subscription-1",
      external_origin_order_id: "100",
      kind: "installments",
      status: "active",
      expected_parts: 4,
      currency: "EUR",
      synced_at: Time.current
    }.merge(overrides)
  end

  def part_attributes(overrides = {})
    {
      sequence: 1,
      provider_part_id: "part-1",
      amount: 100,
      currency: "EUR"
    }.merge(overrides)
  end
end
