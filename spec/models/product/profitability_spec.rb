# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Profitability, :aggregate_failures do
  let(:product) { create(:product) }
  let(:active_sale) { create(:sale, status: "pre-ordered") }
  let(:completed_sale) { create(:sale, status: "completed") }

  let!(:partially_paid_item) do
    create(
      :sale_item,
      sale: active_sale,
      product:,
      variant: nil,
      expected_revenue: BigDecimal("100"),
      received_revenue: BigDecimal("50"),
      outstanding_revenue: BigDecimal("50"),
      refunded_revenue: BigDecimal("0")
    )
  end

  let!(:paid_item) do
    create(
      :sale_item,
      sale: completed_sale,
      product:,
      variant: nil,
      expected_revenue: BigDecimal("200"),
      received_revenue: BigDecimal("200"),
      outstanding_revenue: BigDecimal("0"),
      refunded_revenue: BigDecimal("0")
    )
  end

  before do
    create(:expense_rate, rate_percent: 10)
    product.base_variant.update!(selling_price: BigDecimal("60"))

    purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("30"))
    create(:purchase_item, purchase:, sale_item: partially_paid_item, shipping_cost: BigDecimal("10"), expenses: BigDecimal("0"))
    create(:payment, purchase:, value: BigDecimal("25"))
  end

  describe "#profitability_sale_items" do
    it "includes only sale items of active and completed sales" do
      cancelled_sale = create(:sale, status: "cancelled")
      cancelled_item = create(:sale_item, sale: cancelled_sale, product:, variant: nil, expected_revenue: BigDecimal("999"))

      expect(product.profitability_sale_items).to contain_exactly(partially_paid_item, paid_item)
      expect(product.profitability_sale_items).not_to include(cancelled_item)
    end
  end

  describe "#profitability" do
    it "prices every purchased unit at its variant's selling price, sold or not" do
      unsold_purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("20"))
      create(:purchase_item, purchase: unsold_purchase, shipping_cost: BigDecimal("0"), expenses: BigDecimal("0"))

      expect(product.profitability[:potential_sales]).to eq(BigDecimal("120"))
    end

    it "sums item price, shipping, and direct expenses across every purchased unit" do
      unsold_purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("20"))
      create(:purchase_item, :with_direct_expense, purchase: unsold_purchase, shipping_cost: BigDecimal("3"), direct_expense_amount: BigDecimal("2"))

      expect(product.profitability[:expected_total_cost]).to eq(BigDecimal("65"))
    end

    it "estimates OpEx as a percentage of potential sales, not of sold revenue" do
      expect(product.profitability[:business_expenses]).to eq(BigDecimal("6"))
    end

    it "reconciles potential sales minus expected total cost minus OpEx to the expected net profit" do
      summary = product.profitability
      displayed = summary[:potential_sales] - summary[:expected_total_cost] - summary[:business_expenses]

      expect(displayed).to eq(summary[:expected_net_profit])
    end

    it "reports customer money received and supplier money paid separately, netting them into the cash position" do
      summary = product.profitability

      expect(summary[:received_revenue]).to eq(BigDecimal("250"))
      expect(summary[:purchase_paid]).to eq(BigDecimal("25"))
      expect(summary[:cash_position]).to eq(BigDecimal("225"))
    end

    it "counts every purchase paid toward suppliers, whether or not its units sold" do
      unsold_purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("20"))
      create(:purchase_item, purchase: unsold_purchase, shipping_cost: BigDecimal("0"), expenses: BigDecimal("0"))
      create(:payment, purchase: unsold_purchase, value: BigDecimal("15"))

      expect(product.profitability[:purchase_paid]).to eq(BigDecimal("40"))
    end

    it "prices no unit and pays no supplier for a product with no purchases" do
      bare_product = create(:product)

      expect(bare_product.profitability).to include(
        potential_sales: BigDecimal("0"),
        expected_total_cost: BigDecimal("0"),
        business_expenses: BigDecimal("0"),
        expected_net_profit: BigDecimal("0"),
        purchase_paid: BigDecimal("0")
      )
    end

    it "counts a purchase linked only to a variant of the product" do
      variant = create(:variant, product:, selling_price: BigDecimal("45"))
      variant_purchase = create(:purchase, product: nil, variant:, amount: 1, item_price: BigDecimal("10"))
      create(:purchase_item, purchase: variant_purchase, shipping_cost: BigDecimal("0"), expenses: BigDecimal("0"))

      expect(product.profitability[:potential_sales]).to eq(BigDecimal("105"))
    end

    it "excludes a purchase linked to another product's variant" do
      unlinked_product = create(:product)
      other_purchase = create(:purchase, product: unlinked_product, amount: 1, item_price: BigDecimal("13"))
      create(:purchase_item, purchase: other_purchase, shipping_cost: BigDecimal("0"), expenses: BigDecimal("0"))

      expect(product.profitability[:expected_total_cost]).to eq(BigDecimal("40"))
    end

    it "excludes a purchase never received into a warehouse" do
      create(:purchase, product:, amount: 1, item_price: BigDecimal("999"))

      expect(product.profitability[:expected_total_cost]).to eq(BigDecimal("40"))
    end
  end
end
