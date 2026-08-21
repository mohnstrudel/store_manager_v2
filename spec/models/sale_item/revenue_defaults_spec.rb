# frozen_string_literal: true

require "rails_helper"

RSpec.describe SaleItem::RevenueDefaults, :aggregate_failures do
  let(:product) { create(:product) }
  let(:sale) { create(:sale, status: "pre-ordered") }

  describe "manual sale items (no Shopify data)" do
    it "sets expected/received/future/refunded defaults from the sale item price" do
      sale_item = create(:sale_item, sale:, product:, variant: nil, shopify_id: nil, price: BigDecimal("150"))

      expect(sale_item.expected_revenue).to eq(BigDecimal("150"))
      expect(sale_item.received_revenue).to eq(BigDecimal("150"))
      expect(sale_item.outstanding_revenue).to eq(0)
      expect(sale_item.refunded_revenue).to eq(0)
    end

    it "updates defaults when the manual price changes" do
      sale_item = create(:sale_item, sale:, product:, variant: nil, shopify_id: nil, price: BigDecimal("150"))

      sale_item.update!(price: BigDecimal("200"))

      expect(sale_item.expected_revenue).to eq(BigDecimal("200"))
      expect(sale_item.received_revenue).to eq(BigDecimal("200"))
    end

    it "does not clobber an explicitly refunded amount when price is unchanged" do
      sale_item = create(:sale_item, sale:, product:, variant: nil, shopify_id: nil, price: BigDecimal("150"))

      sale_item.update!(refunded_revenue: BigDecimal("50"))

      expect(sale_item.refunded_revenue).to eq(BigDecimal("50"))
      expect(sale_item.expected_revenue).to eq(BigDecimal("150"))
    end
  end

  describe "sale items of an order whose payment split is unknown" do
    let(:unknown_split_sale) do
      create(
        :sale,
        status: "partially-paid",
        expected_revenue: BigDecimal("991.59"),
        received_revenue: nil,
        outstanding_revenue: nil
      )
    end

    it "keeps received and outstanding revenue unset instead of mirroring the price" do
      sale_item = create(
        :sale_item,
        sale: unknown_split_sale,
        product:,
        variant: nil,
        shopify_id: nil,
        price: BigDecimal("622.59")
      )

      expect(sale_item.expected_revenue).to eq(BigDecimal("622.59"))
      expect(sale_item.received_revenue).to be_nil
      expect(sale_item.outstanding_revenue).to be_nil
      expect(sale_item.refunded_revenue).to eq(0)
    end
  end

  describe "Shopify-imported sale items" do
    it "does not overwrite Shopify-imported revenue fields" do
      sale_item = create(
        :sale_item,
        sale:,
        product:,
        variant: nil,
        shopify_id: "gid://shopify/LineItem/1",
        price: BigDecimal("150"),
        expected_revenue: BigDecimal("100"),
        received_revenue: nil,
        outstanding_revenue: nil,
        refunded_revenue: nil
      )

      expect(sale_item.expected_revenue).to eq(BigDecimal("100"))
      expect(sale_item.received_revenue).to be_nil
      expect(sale_item.outstanding_revenue).to be_nil
      expect(sale_item.refunded_revenue).to be_nil
    end
  end
end
