# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Settlement do
  describe ".settlement_status_from_shopify" do
    it "persists paid for PAID with zero outstanding revenue" do
      expect(
        Sale.settlement_status_from_shopify(financial_status: "PAID", outstanding_revenue: BigDecimal("0.00"))
      ).to eq("paid")
    end

    it "persists paid for PAID with nil outstanding revenue" do
      expect(
        Sale.settlement_status_from_shopify(financial_status: "PAID", outstanding_revenue: nil)
      ).to eq("paid")
    end

    it "persists not_fully_paid for PAID with positive outstanding revenue" do
      expect(
        Sale.settlement_status_from_shopify(financial_status: "PAID", outstanding_revenue: BigDecimal("10.00"))
      ).to eq("not_fully_paid")
    end

    it "persists not_fully_paid for PENDING" do
      expect(
        Sale.settlement_status_from_shopify(financial_status: "PENDING", outstanding_revenue: nil)
      ).to eq("not_fully_paid")
    end

    it "persists not_fully_paid for PARTIALLY_PAID" do
      expect(
        Sale.settlement_status_from_shopify(financial_status: "PARTIALLY_PAID", outstanding_revenue: nil)
      ).to eq("not_fully_paid")
    end

    it "keeps a settlement mapping for VOIDED instead of leaving it unmapped" do
      expect(
        Sale.settlement_status_from_shopify(financial_status: "VOIDED", outstanding_revenue: nil)
      ).to eq("not_fully_paid")
    end

    it "keeps a settlement mapping for a fully refunded order with zero outstanding revenue" do
      expect(
        Sale.settlement_status_from_shopify(financial_status: "REFUNDED", outstanding_revenue: BigDecimal("0.00"))
      ).to eq("paid")
    end

    it "raises for an unmapped financial status instead of persisting a placeholder" do
      expect {
        Sale.settlement_status_from_shopify(financial_status: "SOMETHING_NEW", outstanding_revenue: nil)
      }.to raise_error(ArgumentError, 'Unmapped Shopify financial status: "SOMETHING_NEW"')
    end
  end

  describe "settlement_status enum" do
    it "exposes paid, not_fully_paid, and unknown predicate methods" do
      sale = build(:sale, settlement_status: "not_fully_paid")

      expect(sale).to be_not_fully_paid
    end

    it "stays nil until a synchronization classifies the sale" do
      expect(build(:sale).settlement_status).to be_nil
    end
  end

  describe ".economically_included and .economically_excluded" do
    it "excludes a cancelled sale" do
      sale = create(:sale, status: "cancelled")

      expect(Sale.economically_excluded).to include(sale)
      expect(Sale.economically_included).not_to include(sale)
    end

    it "excludes a failed sale" do
      sale = create(:sale, status: "failed")

      expect(Sale.economically_excluded).to include(sale)
    end

    it "excludes a refunded sale" do
      sale = create(:sale, status: "refunded")

      expect(Sale.economically_excluded).to include(sale)
    end

    it "excludes a voided sale by raw financial status" do
      sale = create(:sale, status: "processing", financial_status: "VOIDED")

      expect(Sale.economically_excluded).to include(sale)
    end

    it "excludes a fully refunded sale by refund state" do
      sale = create(:sale, status: "completed", total: BigDecimal("100.00"), refunded_revenue: BigDecimal("100.00"))

      expect(Sale.economically_excluded).to include(sale)
    end

    it "includes a positive not-yet-refunded sale" do
      sale = create(:sale, status: "processing", total: BigDecimal("100.00"), refunded_revenue: nil)

      expect(Sale.economically_included).to include(sale)
      expect(Sale.economically_excluded).not_to include(sale)
    end

    it "includes a partially refunded sale" do
      sale = create(:sale, status: "processing", total: BigDecimal("100.00"), refunded_revenue: BigDecimal("40.00"))

      expect(Sale.economically_included).to include(sale)
    end
  end
end
