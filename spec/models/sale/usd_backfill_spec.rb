# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::UsdBackfill do
  let(:usd_rate) { BigDecimal("1.1250") }

  before do
    create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD", rate: usd_rate)
    create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "CHF", rate: BigDecimal("0.9375"))
    create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "GBP", rate: BigDecimal("0.8700"))
    create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "CAD", rate: BigDecimal("1.5000"))
    create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "AUD", rate: BigDecimal("1.6500"))
  end

  describe ".call" do
    it "leaves an already-settled sale's money untouched" do
      settled = create(:sale, shopify_id: "settled-1", woo_id: nil, settlement_status: "paid",
        shopify_created_at: Date.new(2026, 8, 21), total: BigDecimal("999.00"))

      expect { described_class.call(shopify_currency: "EUR") }.not_to change { settled.reload.total }
    end

    it "converts a historical Shopify order's totals and item price using the shop's verified historical base currency" do
      sale = create(:sale,
        shopify_id: "shopify-1", woo_id: nil, settlement_status: nil,
        shopify_created_at: Date.new(2026, 8, 21), financial_status: "PAID",
        total: BigDecimal("150.00"), discount_total: BigDecimal("0.00"), shipping_total: BigDecimal("0.00"),
        expected_revenue: BigDecimal("150.00"), received_revenue: BigDecimal("150.00"),
        outstanding_revenue: BigDecimal("0.00"), refunded_revenue: BigDecimal("0.00"))
      item = create(:sale_item, sale:, shopify_id: "item-1", woo_id: nil, price: BigDecimal("150.00"), expected_revenue: BigDecimal("150.00"))

      described_class.call(shopify_currency: "CAD")

      expect(sale.reload).to have_attributes(total: BigDecimal("112.50"), settlement_status: "paid")
      expect(item.reload.price).to eq(BigDecimal("112.50"))
    end

    it "converts a historical WooCommerce sale from EUR using woo_created_at and reuses the live settlement mapping" do
      sale = create(:sale,
        shopify_id: nil, woo_id: "woo-1", settlement_status: nil, status: "completed",
        woo_created_at: Date.new(2026, 8, 21),
        total: BigDecimal("100.00"), discount_total: BigDecimal("0.00"), shipping_total: BigDecimal("0.00"),
        expected_revenue: BigDecimal("100.00"), received_revenue: BigDecimal("100.00"),
        outstanding_revenue: BigDecimal("0.00"), refunded_revenue: BigDecimal("0.00"))
      item = create(:sale_item, sale:, shopify_id: nil, woo_id: "item-1", price: BigDecimal("100.00"), expected_revenue: BigDecimal("100.00"))

      described_class.call(shopify_currency: "GBP")

      expect(sale.reload).to have_attributes(total: BigDecimal("112.50"), settlement_status: "paid")
      expect(item.reload.price).to eq(BigDecimal("112.50"))
    end

    it "backfills a manual sale's settlement_status to unknown without converting its money" do
      manual = create(:sale, shopify_id: nil, woo_id: nil, settlement_status: nil, total: BigDecimal("500.00"))

      expect {
        described_class.call(shopify_currency: "EUR")
      }.not_to change { manual.reload.total }
      expect(manual.reload.settlement_status).to eq("unknown")
    end

    it "leaves purchase-side USD data untouched" do
      purchase = create(:purchase, item_price: BigDecimal("1030.0"))

      expect { described_class.call(shopify_currency: "EUR") }.not_to change { purchase.reload.item_price }
    end

    it "leaves a Shopify sale with no external date unchanged and reports it as unresolved" do
      sale = create(:sale, shopify_id: "shopify-2", woo_id: nil, settlement_status: nil,
        shopify_created_at: nil, total: BigDecimal("150.00"))

      result = described_class.call(shopify_currency: "CAD")

      expect(sale.reload).to have_attributes(total: BigDecimal("150.00"), settlement_status: nil)
      expect(result.unresolved_sale_ids).to eq([sale.id])
    end

    it "reallocates converted item received, outstanding, and refunded revenue exactly once from the converted sale totals" do
      sale = create(:sale,
        shopify_id: "shopify-3", woo_id: nil, settlement_status: nil,
        shopify_created_at: Date.new(2026, 8, 21), financial_status: "PARTIALLY_PAID",
        total: BigDecimal("100.00"), discount_total: BigDecimal("0.00"), shipping_total: BigDecimal("10.00"),
        expected_revenue: BigDecimal("100.00"), received_revenue: BigDecimal("60.00"),
        outstanding_revenue: BigDecimal("40.00"), refunded_revenue: BigDecimal("0.00"))
      item_a = create(:sale_item, sale:, shopify_id: "item-a", woo_id: nil, price: BigDecimal("60.00"), expected_revenue: BigDecimal("60.00"))
      item_b = create(:sale_item, sale:, shopify_id: "item-b", woo_id: nil, price: BigDecimal("40.00"), expected_revenue: BigDecimal("40.00"))

      described_class.call(shopify_currency: "EUR")

      expect(sale.reload).to have_attributes(
        total: BigDecimal("112.50"),
        received_revenue: BigDecimal("67.50"),
        outstanding_revenue: BigDecimal("45.00"),
        settlement_status: "not_fully_paid"
      )
      expect(item_a.reload).to have_attributes(received_revenue: BigDecimal("40.50"), outstanding_revenue: BigDecimal("27.00"), refunded_revenue: BigDecimal("0.00"))
      expect(item_b.reload).to have_attributes(received_revenue: BigDecimal("27.00"), outstanding_revenue: BigDecimal("18.00"), refunded_revenue: BigDecimal("0.00"))
    end

    it "converts Seal and Shopify payment-plan and part money in every observed currency using the origin sale date", :aggregate_failures do
      sale = create(:sale, shopify_id: "shopify-4", woo_id: nil, settlement_status: nil,
        shopify_created_at: Date.new(2026, 8, 21), financial_status: "PAID",
        total: BigDecimal("10.00"), received_revenue: BigDecimal("10.00"), outstanding_revenue: BigDecimal("0.00"))
      create(:sale_item, sale:, shopify_id: "item-4", woo_id: nil, price: BigDecimal("10.00"), expected_revenue: BigDecimal("10.00"))

      currencies = {
        "EUR" => {total: "100.00", part: "40.00"},
        "USD" => {total: "100.00", part: "40.00"},
        "CHF" => {total: "93.75", part: "37.50"},
        "GBP" => {total: "87.00", part: "34.80"},
        "CAD" => {total: "150.00", part: "60.00"},
        "AUD" => {total: "165.00", part: "66.00"}
      }
      plans = currencies.map do |currency, amounts|
        plan = SalePaymentPlan.create!(
          provider: "seal", external_id: "sub-#{currency}", kind: "installments",
          expected_parts: 1, synced_at: Time.current, origin_sale: sale,
          currency:, projected_total: BigDecimal(amounts.fetch(:total))
        )
        plan.parts.create!(sequence: 1, currency:, amount: BigDecimal(amounts.fetch(:part)))
        [currency, plan]
      end.to_h

      described_class.call(shopify_currency: "USD")

      expect(plans.fetch("EUR").reload.projected_total).to eq(BigDecimal("112.50"))
      expect(plans.fetch("USD").reload.projected_total).to eq(BigDecimal("100.00"))
      expect(plans.fetch("CHF").reload.projected_total).to eq(BigDecimal("112.50"))
      expect(plans.fetch("GBP").reload.projected_total).to eq(BigDecimal("112.50"))
      expect(plans.fetch("CAD").reload.projected_total).to eq(BigDecimal("112.50"))
      expect(plans.fetch("AUD").reload.projected_total).to eq(BigDecimal("112.50"))
      currencies.each_key do |currency|
        expected_part = (currency == "USD") ? BigDecimal("40.00") : BigDecimal("45.00")
        expect(plans.fetch(currency).parts.first.reload.amount).to eq(expected_part)
      end
    end

    it "rolls back an atomically failed sale, leaving its settlement_status null" do
      sale = create(:sale, shopify_id: "shopify-5", woo_id: nil, settlement_status: nil,
        shopify_created_at: Date.new(2026, 8, 21), financial_status: "PAID",
        total: BigDecimal("100.00"))
      # 999999.99 GBP converts well past decimal(8,2)'s ceiling, so the item write raises.
      create(:sale_item, sale:, shopify_id: "item-5", woo_id: nil, price: BigDecimal("999999.99"), expected_revenue: BigDecimal("999999.99"))

      result = described_class.call(shopify_currency: "GBP")

      expect(sale.reload).to have_attributes(total: BigDecimal("100.00"), settlement_status: nil)
      expect(result.failed_sale_ids).to eq([sale.id])
    end

    it "resumes on the remaining sale after a failure is repaired, without reconverting the sale that already succeeded" do
      failing_sale = create(:sale, shopify_id: "shopify-6", woo_id: nil, settlement_status: nil,
        shopify_created_at: Date.new(2026, 8, 21), financial_status: "PAID", total: BigDecimal("100.00"))
      failing_item = create(:sale_item, sale: failing_sale, shopify_id: "item-6", woo_id: nil,
        price: BigDecimal("999999.99"), expected_revenue: BigDecimal("999999.99"))
      succeeding_sale = create(:sale, shopify_id: "shopify-7", woo_id: nil, settlement_status: nil,
        shopify_created_at: Date.new(2026, 8, 21), financial_status: "PAID", total: BigDecimal("100.00"))
      create(:sale_item, sale: succeeding_sale, shopify_id: "item-7", woo_id: nil, price: BigDecimal("100.00"), expected_revenue: BigDecimal("100.00"))

      first_result = described_class.call(shopify_currency: "EUR")

      expect(first_result.failed_sale_ids).to eq([failing_sale.id])
      expect(first_result.converted_sale_ids).to eq([succeeding_sale.id])

      failing_item.update_columns(price: BigDecimal("100.00"), expected_revenue: BigDecimal("100.00"))

      second_result = nil
      expect {
        second_result = described_class.call(shopify_currency: "EUR")
      }.not_to change { succeeding_sale.reload.total }

      expect(second_result.converted_sale_ids).to eq([failing_sale.id])
      expect(failing_sale.reload).to have_attributes(total: BigDecimal("112.50"), settlement_status: "paid")
    end

    it "produces no changes and selects no already-converted sale on a second run" do
      sale = create(:sale, shopify_id: "shopify-8", woo_id: nil, settlement_status: nil,
        shopify_created_at: Date.new(2026, 8, 21), financial_status: "PAID", total: BigDecimal("100.00"))
      create(:sale_item, sale:, shopify_id: "item-8", woo_id: nil, price: BigDecimal("100.00"), expected_revenue: BigDecimal("100.00"))

      described_class.call(shopify_currency: "EUR")

      second_result = nil
      expect {
        second_result = described_class.call(shopify_currency: "EUR")
      }.not_to change { sale.reload.total }
      expect(second_result.converted_sale_ids).to eq([])
    end

    it "reports converted, unresolved, and failed counts and identifiers that match committed database state" do
      converted_sale = create(:sale, shopify_id: "shopify-9", woo_id: nil, settlement_status: nil,
        shopify_created_at: Date.new(2026, 8, 21), financial_status: "PAID", total: BigDecimal("100.00"))
      create(:sale_item, sale: converted_sale, shopify_id: "item-9", woo_id: nil, price: BigDecimal("100.00"), expected_revenue: BigDecimal("100.00"))
      unresolved_sale = create(:sale, shopify_id: "shopify-10", woo_id: nil, settlement_status: nil, shopify_created_at: nil)
      manual_sale = create(:sale, shopify_id: nil, woo_id: nil, settlement_status: nil)

      result = described_class.call(shopify_currency: "EUR")

      expect(result.converted_sale_ids.sort).to eq([converted_sale.id, manual_sale.id].sort)
      expect(result.unresolved_sale_ids).to eq([unresolved_sale.id])
      expect(result.failed_sale_ids).to eq([])
      expect(converted_sale.reload.settlement_status).to eq("paid")
      expect(unresolved_sale.reload.settlement_status).to be_nil
      expect(manual_sale.reload.settlement_status).to eq("unknown")
    end
  end
end
