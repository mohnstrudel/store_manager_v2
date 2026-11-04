# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Settlement do
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

  describe ".fully_refunded" do
    it "selects sales whose refund reaches the total and agrees with the record predicate" do
      equal = create(:sale, total: BigDecimal("100.00"), refunded_revenue: BigDecimal("100.00"))
      over = create(:sale, total: BigDecimal("100.00"), refunded_revenue: BigDecimal("100.01"))
      zero_total_zero_refund = create(:sale, total: BigDecimal(0), refunded_revenue: BigDecimal(0))
      partial = create(:sale, total: BigDecimal("100.00"), refunded_revenue: BigDecimal("99.99"))
      zero_refund = create(:sale, total: BigDecimal("100.00"), refunded_revenue: BigDecimal(0))
      nil_refund = create(:sale, total: BigDecimal("100.00"), refunded_revenue: nil)
      nil_total = create(:sale, total: nil, refunded_revenue: BigDecimal("100.00"))
      nil_both = create(:sale, total: nil, refunded_revenue: nil)
      all_sales = [equal, over, zero_total_zero_refund, partial, zero_refund, nil_refund, nil_total, nil_both]

      expect(Sale.fully_refunded).to contain_exactly(equal, over, zero_total_zero_refund)
      expect(all_sales.select(&:fully_refunded?)).to contain_exactly(equal, over, zero_total_zero_refund)
    end

    it "selects nothing when no sale exists" do
      expect(Sale.fully_refunded).to be_empty
    end
  end

  describe "#economically_excluded?" do
    it "mirrors the scope for a cancelled sale" do
      sale = build(:sale, status: "cancelled")

      expect(sale.economically_excluded?).to be(true)
    end

    it "mirrors the scope for a fully refunded sale" do
      sale = build(:sale, status: "completed", total: BigDecimal("100.00"), refunded_revenue: BigDecimal("100.00"))

      expect(sale.economically_excluded?).to be(true)
    end

    it "is false for a positive not-yet-refunded sale" do
      sale = build(:sale, status: "processing", total: BigDecimal("100.00"), refunded_revenue: nil)

      expect(sale.economically_excluded?).to be(false)
    end
  end
end
