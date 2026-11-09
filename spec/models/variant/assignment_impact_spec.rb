# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::AssignmentImpact do
  subject(:impact) { described_class.new(integrity: Variant::AssignmentIntegrity.new) }

  def broken_line(status:, revenue:, product: create(:product), sale: create(:sale, status:))
    create(:sale_item, sale:, product:, expected_revenue: revenue).tap do |line|
      line.update_columns(variant_id: nil)
    end
  end

  describe "the worked example" do
    let!(:first_active) { broken_line(status: "processing", revenue: 100) }
    let!(:second_active) { broken_line(status: "pre-ordered", revenue: 100) }
    let!(:completed) { broken_line(status: "completed", revenue: 50) }
    let!(:cancelled) { broken_line(status: "cancelled", revenue: 30) }

    it "orders active, then other, then closed, with the later line breaking a revenue tie" do
      expect(impact.order_rows.to_a).to eq([second_active, first_active, completed, cancelled])
    end
  end

  describe "#consequences" do
    let(:product) { create(:product).tap { |product| create(:variant, :with_color, product:, color_value: "Red") } }

    def order_line(status:, linked: 0, product: self.product)
      create(:sale_item, sale: create(:sale, status:), product:, variant: product.variants.last).tap do |line|
        line.update_columns(variant_id: nil, qty: 2, purchase_items_count: linked)
      end
    end

    it "reports unreserved units, miscounted debt, and the unrecorded Variant for an active unlinked line" do
      expect(impact.consequences(order_line(status: "processing"), reason: "missing_variant")).to eq([
        {kind: :units_not_reserved, units: 2},
        {kind: :debt_miscounted},
        {kind: :variant_not_recorded}
      ])
    end

    it "reports only miscounted debt and the unrecorded Variant once every unit is linked" do
      expect(impact.consequences(order_line(status: "processing", linked: 2), reason: "missing_variant")).to eq([
        {kind: :debt_miscounted},
        {kind: :variant_not_recorded}
      ])
    end

    it "reports only the unrecorded Variant for a cancelled order" do
      expect(impact.consequences(order_line(status: "cancelled"), reason: "missing_variant")).to eq([{kind: :variant_not_recorded}])
    end

    it "reports only the unrecorded Variant for an order that is neither active nor closed" do
      expect(impact.consequences(order_line(status: "completed"), reason: "missing_variant")).to eq([{kind: :variant_not_recorded}])
    end

    it "reports the wrong recorded Variant when the Variant belongs to another Product" do
      expect(impact.consequences(order_line(status: "refunded"), reason: "product_mismatch")).to eq([{kind: :wrong_variant_recorded}])
    end

    it "adds that the order is not updating when its import failed" do
      failure = Sale::ImportFailure.new(store_name: "woo", first_failed_at: Time.zone.local(2026, 11, 9))

      expect(impact.consequences(order_line(status: "processing"), reason: "missing_variant", import_failure: failure)).to eq([
        {kind: :units_not_reserved, units: 2},
        {kind: :debt_miscounted},
        {kind: :variant_not_recorded},
        {kind: :not_updating}
      ])
    end

    it "adds that a closed order is not updating when its import failed" do
      failure = Sale::ImportFailure.new(store_name: "woo", first_failed_at: Time.zone.local(2026, 11, 9))

      expect(impact.consequences(order_line(status: "cancelled"), reason: "missing_variant", import_failure: failure)).to eq([
        {kind: :variant_not_recorded},
        {kind: :not_updating}
      ])
    end

    it "states only the unrecorded Variant for a fully linked active line of a Product without real Variants" do
      line = order_line(status: "processing", linked: 2, product: create(:product))

      expect(impact.consequences(line, reason: "missing_variant")).to eq([{kind: :variant_not_recorded}])
    end

    it "does not report units of an installment line as unreserved" do
      line = order_line(status: "processing", product: create(:product))
      line.update_columns(origin_sale_item_id: create(:sale_item).id)

      expect(impact.consequences(line, reason: "missing_variant")).to eq([{kind: :variant_not_recorded}])
    end
  end

  describe "#product_rows" do
    it "counts orders, active orders, closed lines, and revenue per Product, most orders first" do
      busy = create(:product)
      quiet = create(:product)
      shared_sale = create(:sale, status: "processing")
      2.times { broken_line(status: nil, revenue: 40, product: busy, sale: shared_sale) }
      broken_line(status: "cancelled", revenue: 40, product: busy)
      broken_line(status: "trash", revenue: 15, product: busy)
      broken_line(status: "completed", revenue: 500, product: quiet)

      rows = impact.product_rows.map do |row|
        row.attributes.slice("product_id", "order_count", "active_order_count", "closed_line_count", "revenue")
      end

      expect(rows).to eq([
        {"product_id" => busy.id, "order_count" => 3, "active_order_count" => 1, "closed_line_count" => 2, "revenue" => 135},
        {"product_id" => quiet.id, "order_count" => 1, "active_order_count" => 0, "closed_line_count" => 0, "revenue" => 500}
      ])
    end

    it "keeps the reason filter" do
      missing = broken_line(status: "processing", revenue: 10)
      mismatched = create(:sale_item, expected_revenue: 10)
      mismatched.update_columns(variant_id: create(:product).base_variant.id)

      expect(impact.product_rows(reason: "missing_variant").map(&:product_id)).to eq([missing.product_id])
    end
  end

  describe "#order_rows" do
    it "classifies cancelled, failed, refunded, and trash as closed" do
      closed = %w[cancelled failed refunded trash].map { |status| broken_line(status:, revenue: 10) }
      broken_line(status: "completed", revenue: 10)
      broken_line(status: "processing", revenue: 10)

      expect(impact.order_rows(scope: "closed")).to match_array(closed)
    end

    it "limits the active scope to active statuses" do
      active = broken_line(status: "processing", revenue: 10)
      broken_line(status: "completed", revenue: 10)
      broken_line(status: "trash", revenue: 10)

      expect(impact.order_rows(scope: "active")).to contain_exactly(active)
    end

    it "treats a status outside active and closed as other" do
      trash = broken_line(status: "trash", revenue: 900)
      on_hold = broken_line(status: "on-hold", revenue: 1)
      no_status = broken_line(status: nil, revenue: 2)
      active = broken_line(status: "processing", revenue: 3)

      expect(impact.order_rows.to_a).to eq([active, no_status, on_hold, trash])
    end

    it "sorts revenue descending within a priority and puts a blank amount last" do
      blank = broken_line(status: "processing", revenue: nil)
      small = broken_line(status: "processing", revenue: 10)
      large = broken_line(status: "processing", revenue: 200)

      expect(impact.order_rows.to_a).to eq([large, small, blank])
    end

    it "filters to one Product" do
      product = create(:product)
      line = broken_line(status: "processing", revenue: 10, product:)
      broken_line(status: "processing", revenue: 10)

      expect(impact.order_rows(product_id: product.id)).to contain_exactly(line)
    end

    it "keeps the reason filter" do
      missing = broken_line(status: "processing", revenue: 10)
      mismatched = create(:sale_item, expected_revenue: 10)
      mismatched.update_columns(variant_id: create(:product).base_variant.id)

      expect(impact.order_rows(reason: "missing_variant")).to contain_exactly(missing)
      expect(impact.order_rows(reason: "product_mismatch")).to contain_exactly(mismatched)
    end
  end
end
