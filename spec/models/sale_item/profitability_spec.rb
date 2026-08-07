# frozen_string_literal: true

require "rails_helper"

RSpec.describe SaleItem::Profitability, :aggregate_failures do
  let(:product) { create(:product) }
  let(:sale) { create(:sale, status: "pre-ordered") }
  let(:sale_item) do
    create(
      :sale_item,
      sale:,
      product:,
      variant: nil,
      expected_revenue: BigDecimal("300"),
      received_revenue: BigDecimal("100"),
      outstanding_revenue: BigDecimal("200")
    )
  end

  before do
    purchase = create(:purchase, product:, amount: 1, item_price: BigDecimal("100"))
    create(:purchase_item, :with_direct_expense, purchase:, sale_item:, shipping_cost: BigDecimal("15"), direct_expense_amount: BigDecimal("5"))
  end

  describe "#purchase_cost" do
    it "sums item price, shipping cost, and direct expenses of linked purchase items" do
      expect(sale_item.purchase_cost).to eq(BigDecimal("120"))
    end

    it "is zero without linked purchase items" do
      unlinked_item = create(:sale_item, sale:, product:, variant: nil)

      expect(unlinked_item.purchase_cost).to eq(0)
    end
  end

  describe "#direct_expenses" do
    it "sums only the ad-hoc expenses recorded against the linked purchase items" do
      expect(sale_item.direct_expenses).to eq(BigDecimal("5"))
    end

    it "is zero without linked purchase items" do
      unlinked_item = create(:sale_item, sale:, product:, variant: nil)

      expect(unlinked_item.direct_expenses).to eq(0)
    end
  end

  describe "#business_expenses" do
    it "applies the combined expense rate to expected revenue" do
      create(:expense_rate, rate_percent: 10)

      expect(sale_item.business_expenses).to eq(BigDecimal("30"))
    end

    it "is zero without expense rates" do
      expect(sale_item.business_expenses).to eq(0)
    end
  end

  describe "#realized_profit" do
    it "uses only revenue already received" do
      create(:expense_rate, rate_percent: 10)

      expect(sale_item.realized_profit).to eq(BigDecimal("-50"))
    end
  end

  describe "#expected_final_profit" do
    it "uses the full expected revenue" do
      create(:expense_rate, rate_percent: 10)

      expect(sale_item.expected_final_profit).to eq(BigDecimal("150"))
    end
  end

  describe "#future_revenue" do
    it "returns the outstanding revenue" do
      expect(sale_item.future_revenue).to eq(BigDecimal("200"))
    end
  end

  describe "#profitability_status" do
    it "is profitable when expected final profit is positive" do
      expect(sale_item.profitability_status).to eq(:profitable)
    end

    it "is loss when expected final profit is negative" do
      sale_item.update!(expected_revenue: BigDecimal("100"))

      expect(sale_item.profitability_status).to eq(:loss)
    end

    it "is break_even when expected final profit is zero" do
      sale_item.update!(expected_revenue: BigDecimal("120"))

      expect(sale_item.profitability_status).to eq(:break_even)
    end

    it "is unknown when expected revenue was never recorded" do
      sale_item.update!(expected_revenue: nil)

      expect(sale_item.profitability_status).to eq(:unknown)
    end
  end
end
