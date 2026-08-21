# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductHelper do
  describe "#product_profitability_props" do
    let(:product) { create(:product) }

    before do
      create(:expense_rate, rate_percent: 10)
      product.base_variant.update!(selling_price: BigDecimal("150"))
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
      create(:payment, purchase:, value: BigDecimal("80"))
    end

    it "prices potential sales at the variant's selling price and folds shipping and direct expenses into the expected total cost" do
      props = helper.product_profitability_props(product)

      expect(props[:potential_sales]).to eq("150")
      expect(props[:expected_total_cost]).to eq("120")
    end

    it "nets the expected total cost and estimated OpEx out of potential sales for the expected net profit" do
      props = helper.product_profitability_props(product)

      expect(props[:business_expenses]).to eq("15")
      expect(props[:expected_net_profit]).to eq("15")
    end

    it "reports customer money kept and purchase paid separately and nets them into the cash position" do
      props = helper.product_profitability_props(product)

      expect(props[:collected_revenue]).to eq("100")
      expect(props[:purchase_paid]).to eq("80")
      expect(props[:cash_position]).to eq("20")
    end

    it "omits values no component reads" do
      props = helper.product_profitability_props(product)

      expect(props).not_to have_key(:expense_rate_percent)
      expect(props).not_to have_key(:status)
      expect(props).not_to have_key(:margin_percent)
      expect(props).not_to have_key(:has_sale_items)
      expect(props).not_to have_key(:invested_total)
      expect(props).not_to have_key(:remaining_inventory_cost)
      expect(props).not_to have_key(:purchased_units_total)
      expect(props).not_to have_key(:sold_units_total)
      expect(props).not_to have_key(:remaining_units_total)
      expect(props).not_to have_key(:merchandise_cost)
      expect(props).not_to have_key(:direct_expenses)
      expect(props).not_to have_key(:outstanding_revenue)
      expect(props).not_to have_key(:refunded_revenue)
      expect(props).not_to have_key(:received_revenue)
      expect(props).not_to have_key(:counted_sales_total)
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
