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

    purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("30"))
    create(:purchase_item, purchase:, sale_item: partially_paid_item, shipping_cost: BigDecimal("10"), expenses: BigDecimal("0"))
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
    it "aggregates revenue, costs, and profits across sale items" do
      summary = product.profitability

      expect(summary).to include(
        expected_revenue: BigDecimal("300"),
        received_revenue: BigDecimal("250"),
        outstanding_revenue: BigDecimal("50"),
        refunded_revenue: BigDecimal("0"),
        purchase_cost: BigDecimal("40"),
        business_expenses: BigDecimal("30"),
        realized_profit: BigDecimal("180"),
        expected_final_profit: BigDecimal("230")
      )
    end

    it "names direct expenses beside the full cost of goods, mirroring Sale::Profitability" do
      summary = product.profitability

      expect(summary[:purchase_cost]).to eq(BigDecimal("40"))
      expect(summary[:direct_expenses]).to eq(BigDecimal("0"))
      expect(summary[:merchandise_cost]).to eq(BigDecimal("40"))
    end

    it "includes direct expenses of linked purchase items in the split" do
      purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("20"))
      create(:purchase_item, :with_direct_expense, purchase:, sale_item: paid_item, shipping_cost: BigDecimal("5"), direct_expense_amount: BigDecimal("7"))

      expect(product.profitability).to include(
        direct_expenses: BigDecimal("7"),
        purchase_cost: BigDecimal("72"),
        merchandise_cost: BigDecimal("65")
      )
    end

    it "reconciles the displayed terms to the expected final profit" do
      purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("20"))
      create(:purchase_item, :with_direct_expense, purchase:, sale_item: paid_item, shipping_cost: BigDecimal("5"), direct_expense_amount: BigDecimal("7"))
      create(:expense_rate, rate_percent: 10)

      summary = product.profitability
      displayed = summary[:expected_revenue] -
        summary[:merchandise_cost] -
        summary[:direct_expenses] -
        summary[:business_expenses]

      expect(displayed).to eq(summary[:expected_final_profit])
    end

    it "reports whether the product has sale items this equation counts, so the frontend never has to re-derive it" do
      expect(product.profitability[:has_sale_items]).to eq(true)

      bare_product = create(:product)
      expect(bare_product.profitability[:has_sale_items]).to eq(false)
    end

    it "counts the orders these figures were added up from, so the page can say what a total covers" do
      expect(product.profitability[:counted_sales_total]).to eq(2)
    end

    it "counts an order once however many lines of the product it carries" do
      create(
        :sale_item,
        sale: active_sale,
        product:,
        variant: nil,
        expected_revenue: BigDecimal("40"),
        received_revenue: BigDecimal("40"),
        outstanding_revenue: BigDecimal("0"),
        refunded_revenue: BigDecimal("0")
      )

      # Three sale items, still the two orders a reader would count.
      expect(product.profitability_sale_items.count).to eq(3)
      expect(product.profitability[:counted_sales_total]).to eq(2)
    end

    it "counts no orders for a product that has never sold" do
      expect(create(:product).profitability[:counted_sales_total]).to eq(0)
    end

    it "calculates the margin from the expected final profit" do
      expect(product.profitability[:margin_percent]).to eq(BigDecimal("76.67"))
    end

    it "is profitable when the expected final profit is positive" do
      expect(product.profitability[:status]).to eq(:profitable)
    end

    it "reports a loss when costs exceed expected revenue" do
      expensive_purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("400"))
      create(:purchase_item, purchase: expensive_purchase, sale_item: paid_item, shipping_cost: BigDecimal("0"), expenses: BigDecimal("0"))

      expect(product.profitability[:status]).to eq(:loss)
    end

    it "returns empty totals without qualifying sale items" do
      bare_product = create(:product)
      summary = bare_product.profitability

      expect(summary).to include(
        expected_revenue: 0,
        received_revenue: 0,
        realized_profit: 0,
        expected_final_profit: 0,
        margin_percent: nil,
        status: :break_even
      )
    end

    it "is unknown when no qualifying sale item has recorded revenue" do
      partially_paid_item.update!(expected_revenue: nil)
      paid_item.update!(expected_revenue: nil)

      expect(product.profitability[:status]).to eq(:unknown)
    end

    it "is not unknown when at least one qualifying sale item has recorded revenue" do
      partially_paid_item.update!(expected_revenue: nil)

      expect(product.profitability[:status]).not_to eq(:unknown)
    end
  end

  describe "#inventory_economics" do
    it "counts warehoused units and the cost frozen in unsold stock" do
      unsold_purchase = create(:purchase, product:, amount: 2, item_price: BigDecimal("20"))
      create(:purchase_item, :with_direct_expense, purchase: unsold_purchase, shipping_cost: BigDecimal("3"), direct_expense_amount: BigDecimal("2"))
      create(:purchase_item, purchase: unsold_purchase, shipping_cost: BigDecimal("1"), expenses: BigDecimal("0"))

      expect(product.inventory_economics).to eq(
        purchased_units: 3,
        sold_units: 1,
        remaining_units: 2,
        invested_total: BigDecimal("86"),
        remaining_inventory_cost: BigDecimal("46")
      )
    end

    it "invests over every purchased unit, including one linked to a cancelled sale" do
      cancelled_sale = create(:sale, status: "cancelled")
      cancelled_item = create(:sale_item, sale: cancelled_sale, product:, variant: nil, expected_revenue: BigDecimal("999"))
      cancelled_purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("25"))
      create(:purchase_item, purchase: cancelled_purchase, sale_item: cancelled_item, shipping_cost: BigDecimal("5"), expenses: BigDecimal("0"))
      unsold_purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("20"))
      create(:purchase_item, purchase: unsold_purchase, shipping_cost: BigDecimal("3"), expenses: BigDecimal("0"))

      inventory = product.inventory_economics

      expect(inventory[:invested_total]).to eq(BigDecimal("93"))
      expect(product.profitability[:purchase_cost] + inventory[:remaining_inventory_cost]).to eq(BigDecimal("63"))
    end

    it "counts purchases linked only to a variant of the product" do
      variant = create(:variant, product:)
      variant_purchase = create(:purchase, product: nil, variant:, amount: 1, item_price: BigDecimal("10"))
      create(:purchase_item, purchase: variant_purchase, shipping_cost: BigDecimal("0"), expenses: BigDecimal("0"))

      expect(product.inventory_economics).to include(purchased_units: 2, remaining_units: 1)
    end

    it "rejects inventory with a Variant owned by another Product" do
      other_product = create(:product)
      other_variant = create(:variant, product: other_product)
      mismatched_purchase = build(
        :purchase,
        product:,
        variant: other_variant,
        amount: 1,
        item_price: BigDecimal(10),
        supplier: create(:supplier)
      )

      expect(mismatched_purchase).not_to be_valid
      expect(mismatched_purchase.errors[:variant]).to be_present
    end

    it "reports zero sold units when sales are not linked to purchase items" do
      unlinked_product = create(:product)
      sale = create(:sale, status: "completed")
      create(:sale_item, sale:, product: unlinked_product, variant: nil, expected_revenue: BigDecimal("50"))
      purchase = create(:purchase, product: unlinked_product, amount: 1, item_price: BigDecimal("10"))
      create(:purchase_item, :with_direct_expense, purchase:, shipping_cost: BigDecimal("2"), direct_expense_amount: BigDecimal("1"))

      expect(unlinked_product.inventory_economics).to eq(
        purchased_units: 1,
        sold_units: 0,
        remaining_units: 1,
        invested_total: BigDecimal("13"),
        remaining_inventory_cost: BigDecimal("13")
      )
    end
  end
end
