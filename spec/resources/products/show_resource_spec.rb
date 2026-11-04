# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::ShowResource do
  include Rails.application.routes.url_helpers
  include FormattingHelper

  def show(product, can_view_profitability: true)
    described_class.new({
      product: Product.for_details.find(product.id),
      purchases: product.purchases,
      can_pull_from_shopify: false,
      can_view_profitability:
    }).serializable_hash.deep_symbolize_keys
  end

  describe "profitability" do
    let(:product) { create(:product) }

    before do
      create(:expense_rate, rate_percent: 10)
      product.base_variant.update!(selling_price: BigDecimal(150))
      sale = create(:sale, status: "pre-ordered")
      sale_item = create(
        :sale_item,
        product:,
        variant: nil,
        sale:,
        qty: 1,
        expected_revenue: BigDecimal(300),
        received_revenue: BigDecimal(100),
        outstanding_revenue: BigDecimal(200)
      )
      purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal(100))
      create(:purchase_item, :with_direct_expense, purchase:, sale_item:, shipping_cost: BigDecimal(15), direct_expense_amount: BigDecimal(5))
      create(:payment, purchase:, value: BigDecimal(80))
    end

    it "prices potential sales at the variant's selling price and folds shipping and direct expenses into the expected total cost" do
      profitability = show(product)[:profitability]

      expect(profitability[:potential_sales]).to eq("150")
      expect(profitability[:expected_total_cost]).to eq("120")
    end

    it "nets the expected total cost and estimated OpEx out of potential sales for the expected net profit" do
      profitability = show(product)[:profitability]

      expect(profitability[:business_expenses]).to eq("15")
      expect(profitability[:expected_net_profit]).to eq("15")
    end

    it "reports customer money kept and purchase paid separately and nets them into the cash position" do
      profitability = show(product)[:profitability]

      expect(profitability[:collected_revenue]).to eq("100")
      expect(profitability[:purchase_paid]).to eq("80")
      expect(profitability[:cash_position]).to eq("20")
    end

    it "carries only the values the dashboard reads" do
      expect(show(product)[:profitability].keys).to contain_exactly(
        :potential_sales, :expected_total_cost, :business_expenses, :expected_net_profit,
        :collected_revenue, :purchase_paid, :cash_position
      )
    end

    it "is withheld from staff who cannot view profitability" do
      expect(show(product, can_view_profitability: false)[:profitability]).to be_nil
    end
  end

  describe "variants" do
    it "shows the calculated theoretical profit even when the purchase cost total formats to zero" do
      create(:expense_rate, rate_percent: BigDecimal("15.0"))
      product = create(:product)
      variant = create(:variant, product:, selling_price: BigDecimal(200))
      purchase = create(:purchase, product:, variant:, item_price: BigDecimal(0))
      create(:purchase_item, purchase:, shipping_cost: BigDecimal(0), expenses: BigDecimal(0))
      create(:purchase_item, purchase:, shipping_cost: BigDecimal(0), expenses: BigDecimal(0))

      row = show(product)[:variants].find { |candidate| candidate[:id] == variant.id }

      expect(row[:total_purchase_cost]).to be_nil
      expect(row[:theoretical_profit]).to eq("170")
    end
  end

  describe "sales" do
    let(:product) { create(:product) }

    it "adds the original shop-currency price recovered from the order's USD rate" do
      sale = create(:sale, status: "processing", shop_currency: "EUR", presentment_currency: "EUR", usd_conversion_rate: BigDecimal("1.1214"), exchange_rate_date: Date.new(2026, 9, 2))
      create(:sale_item, product:, sale:, price: BigDecimal("47.10"))

      expect(show(product)[:active_sales].sole).to include(price: "47", price_original: "42 EUR")
    end

    it "omits the original price when the sale has no conversion rate" do
      sale = create(:sale, status: "processing", shop_currency: nil, usd_conversion_rate: nil)
      create(:sale_item, product:, sale:, price: BigDecimal("47.10"))

      expect(show(product)[:active_sales].sole[:price_original]).to be_nil
    end
  end

  describe "payments" do
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product:) }

    def reconcile_plan(external_origin_order_id:, parts:, external_id: "subscription-1")
      SalePaymentPlan.reconcile(
        attributes: {
          provider: "seal",
          external_id:,
          external_origin_order_id:,
          kind: "installments",
          status: "active",
          expected_parts: parts.size,
          synced_at: Time.current
        },
        parts:
      )
    end

    it "carries the payment's sequence, expected parts, and a link back to the origin sale" do
      origin = create(:sale, status: "processing", shopify_store_id: "gid://shopify/Order/900", shopify_name: "Order #900")
      follow_up = create(:sale, status: "processing", shopify_store_id: "gid://shopify/Order/901")
      create(:sale_item, product:, variant:, sale: follow_up, qty: 1)
      create(:sale_item, product:, variant:, sale: origin, qty: 1)
      reconcile_plan(
        external_origin_order_id: "900",
        parts: [
          {sequence: 1, provider_part_id: "part-1", external_order_id: "900"},
          {sequence: 2, provider_part_id: "part-2", external_order_id: "901"}
        ]
      )

      payment = show(product)[:active_payments].sole

      expect(payment[:sequence]).to eq(2)
      expect(payment[:expected_parts]).to eq(2)
      expect(payment[:origin]).to eq(path: sale_path(origin), identifier: "Order #900")
      expect(payment[:sale_path]).to eq(sale_path(follow_up))
    end

    it "still renders and links correctly when the payment sale item has no purchase item linkage" do
      origin = create(:sale, status: "processing", shopify_store_id: "gid://shopify/Order/910")
      follow_up = create(:sale, status: "processing", shopify_store_id: "gid://shopify/Order/911")
      create(:sale_item, product:, variant:, sale: follow_up, qty: 1)
      create(:sale_item, product:, variant:, sale: origin, qty: 1)
      reconcile_plan(
        external_id: "subscription-2",
        external_origin_order_id: "910",
        parts: [
          {sequence: 1, provider_part_id: "part-3", external_order_id: "910"},
          {sequence: 2, provider_part_id: "part-4", external_order_id: "911"}
        ]
      )

      payment = show(product)[:active_payments].sole

      expect(payment[:purchase_item_path]).to be_nil
      expect(payment[:warehouse]).to eq("")
      expect(payment[:sale_path]).to eq(sale_path(follow_up))
    end
  end

  describe "timestamp columns" do
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

      details = show(product)[:product]

      expect(details[:created_at_columns]).to eq([
        {key: "created", label: "StoreMate", value: format_date(Date.new(2026, 4, 19))},
        {key: "shopify", label: "Shopify", value: format_date(Date.new(2026, 4, 20))}
      ])
      expect(details[:updated_at_columns]).to eq([
        {key: "updated", label: "StoreMate", value: format_date(Date.new(2026, 4, 21))},
        {key: "shopify", label: "Shopify", value: format_date(Date.new(2026, 4, 22))}
      ])
    end
  end
end
