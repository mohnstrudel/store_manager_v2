# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductHelper do
  describe "#product_profitability_props" do
    let(:product) { create(:product) }

    before do
      create(:expense_rate, rate_percent: 10)
      sale = create(:sale, status: "pre-ordered")
      sale_item = create(
        :sale_item,
        product:,
        variant: nil,
        sale:,
        qty: 1,
        expected_revenue: BigDecimal("300"),
        received_revenue: BigDecimal("100"),
        outstanding_revenue: BigDecimal("200")
      )
      purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("100"))
      create(:purchase_item, :with_direct_expense, purchase:, sale_item:, shipping_cost: BigDecimal("15"), direct_expense_amount: BigDecimal("5"))
    end

    it "names direct expenses beside merchandise cost, matching the sale page's own term" do
      props = helper.product_profitability_props(product)

      expect(props[:purchase_cost]).to eq("120")
      expect(props[:direct_expenses]).to eq("5")
      expect(props[:merchandise_cost]).to eq("115")
    end

    it "reports profit on money received beside profit on the full order value" do
      props = helper.product_profitability_props(product)

      expect(props[:realized_profit]).to eq("-50")
      expect(props[:expected_final_profit]).to eq("150")
    end

    it "decides has_sale_items on the backend from the same items the equation aggregates" do
      expect(helper.product_profitability_props(product)[:has_sale_items]).to eq(true)

      bare_product = create(:product)
      expect(helper.product_profitability_props(bare_product)[:has_sale_items]).to eq(false)
    end

    it "passes the counted order total through so the hints can name what a figure covers" do
      expect(helper.product_profitability_props(product)[:counted_sales_total]).to eq(1)
    end

    it "omits values no component reads" do
      props = helper.product_profitability_props(product)

      expect(props).not_to have_key(:item_cost_total)
      expect(props).not_to have_key(:shipping_cost_total)
      expect(props).not_to have_key(:received_percent)
      expect(props).not_to have_key(:refunded_percent)
    end
  end

  describe "#variant_props" do
    it "shows the calculated theoretical profit even when the purchase cost total formats to zero" do
      create(:expense_rate, rate_percent: BigDecimal("15.0"))
      product = create(:product)
      variant = create(:variant, product:, selling_price: BigDecimal("200"))
      purchase = create(:purchase, product:, variant:, item_price: BigDecimal("0"))
      create(:purchase_item, purchase:, shipping_cost: BigDecimal("0"), expenses: BigDecimal("0"))
      create(:purchase_item, purchase:, shipping_cost: BigDecimal("0"), expenses: BigDecimal("0"))

      purchase_cost_totals = product.variant_purchase_cost_totals
      props = helper.variant_props(variant, {}, {}, purchase_cost_totals, can_view_profitability: true)

      expect(props[:total_purchase_cost]).to be_nil
      expect(props[:theoretical_profit]).to eq("170")
    end
  end

  describe "#product_timestamp_columns" do
    it "returns the local timestamp first and only includes populated store timestamps" do
      product = create(:product)
      product.woo_info.destroy!
      product.update_columns( # rubocop:disable Rails/SkipsModelValidations
        created_at: Time.zone.parse("2026-04-19 09:00"),
        updated_at: Time.zone.parse("2026-04-21 14:00")
      )
      product.shopify_info.update!(
        ext_created_at: Time.zone.parse("2026-04-20 10:00"),
        ext_updated_at: Time.zone.parse("2026-04-22 11:00")
      )

      created_columns = helper.product_timestamp_columns(product, :created_at)
      updated_columns = helper.product_timestamp_columns(product, :updated_at)

      aggregate_failures do
        expect(created_columns.pluck(:key)).to eq(%w[created shopify])
        expect(created_columns.pluck(:label)).to eq(["StoreMate", "Shopify"])
        expect(created_columns.map { |column| column[:value].to_date }).to eq(
          [Date.new(2026, 4, 19), Date.new(2026, 4, 20)]
        )

        expect(updated_columns.pluck(:key)).to eq(%w[updated shopify])
        expect(updated_columns.pluck(:label)).to eq(["StoreMate", "Shopify"])
        expect(updated_columns.map { |column| column[:value].to_date }).to eq(
          [Date.new(2026, 4, 21), Date.new(2026, 4, 22)]
        )
      end
    end
  end
end
