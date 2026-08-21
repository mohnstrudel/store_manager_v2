# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::RevenueAllocation, :aggregate_failures do
  describe "#allocate_revenue_to_items!" do
    let(:product) { create(:product) }
    let(:sale) do
      create(
        :sale,
        received_revenue: BigDecimal("90"),
        outstanding_revenue: BigDecimal("210"),
        refunded_revenue: BigDecimal("0")
      )
    end

    def create_item(expected_revenue)
      create(:sale_item, sale:, product:, variant: nil, expected_revenue:)
    end

    it "allocates amounts proportionally by expected line revenue" do
      small_item = create_item(BigDecimal("100"))
      large_item = create_item(BigDecimal("200"))

      sale.allocate_revenue_to_items!

      expect(small_item.reload).to have_attributes(
        received_revenue: BigDecimal("30"),
        outstanding_revenue: BigDecimal("70"),
        refunded_revenue: BigDecimal("0")
      )
      expect(large_item.reload).to have_attributes(
        received_revenue: BigDecimal("60"),
        outstanding_revenue: BigDecimal("140"),
        refunded_revenue: BigDecimal("0")
      )
    end

    it "gives the rounding remainder to the last item so sums stay exact" do
      sale.update!(received_revenue: BigDecimal("100"), outstanding_revenue: nil, refunded_revenue: nil)
      items = Array.new(3) { create_item(BigDecimal("100")) }

      sale.allocate_revenue_to_items!

      received = items.map { |item| item.reload.received_revenue }
      expect(received).to eq([BigDecimal("33.33"), BigDecimal("33.33"), BigDecimal("33.34")])
      expect(received.sum).to eq(BigDecimal("100"))
    end

    it "splits equally when no item has expected revenue" do
      sale.update!(received_revenue: BigDecimal("50"), outstanding_revenue: BigDecimal("0"))
      first_item = create_item(nil)
      second_item = create_item(nil)

      sale.allocate_revenue_to_items!

      expect(first_item.reload.received_revenue).to eq(BigDecimal("25"))
      expect(second_item.reload.received_revenue).to eq(BigDecimal("25"))
    end

    it "allocates only the amounts the sale actually states" do
      # A Woo deposit: the importer knows the order was not refunded but cannot
      # say how much of it was collected. Splitting the unknown amounts would
      # write zeros onto the items and contradict the order itself.
      sale.update!(received_revenue: nil, outstanding_revenue: nil, refunded_revenue: BigDecimal("30"))
      small_item = create_item(BigDecimal("100"))
      large_item = create_item(BigDecimal("200"))

      sale.allocate_revenue_to_items!

      expect(small_item.reload).to have_attributes(
        received_revenue: nil,
        outstanding_revenue: nil,
        refunded_revenue: BigDecimal("10")
      )
      expect(large_item.reload).to have_attributes(
        received_revenue: nil,
        outstanding_revenue: nil,
        refunded_revenue: BigDecimal("20")
      )
    end

    it "leaves items untouched when the sale has no revenue data" do
      sale.update!(received_revenue: nil, outstanding_revenue: nil, refunded_revenue: nil)
      item = create_item(BigDecimal("100"))

      sale.allocate_revenue_to_items!

      expect(item.reload).to have_attributes(
        received_revenue: nil,
        outstanding_revenue: nil,
        refunded_revenue: nil
      )
    end

    it "does nothing without sale items" do
      expect { sale.allocate_revenue_to_items! }.not_to raise_error
    end
  end

  describe "#shipping_shares_by_item_id" do
    let(:product) { create(:product) }
    let(:sale) { create(:sale, shipping_total: BigDecimal("30")) }

    def create_item(expected_revenue)
      create(:sale_item, sale:, product:, variant: nil, expected_revenue:)
    end

    it "allocates shipping proportionally by expected line revenue" do
      small_item = create_item(BigDecimal("100"))
      large_item = create_item(BigDecimal("200"))

      shares = sale.shipping_shares_by_item_id

      expect(shares).to eq(
        small_item.id => BigDecimal("10"),
        large_item.id => BigDecimal("20")
      )
    end

    it "gives the rounding remainder to the last item so sums stay exact" do
      sale.update!(shipping_total: BigDecimal("10"))
      items = Array.new(3) { create_item(BigDecimal("100")) }

      shares = sale.shipping_shares_by_item_id

      expect(items.map { |item| shares[item.id] }).to eq(
        [BigDecimal("3.33"), BigDecimal("3.33"), BigDecimal("3.34")]
      )
    end

    it "returns an empty hash without sale items" do
      expect(sale.shipping_shares_by_item_id).to eq({})
    end
  end
end
