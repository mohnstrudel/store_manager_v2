# frozen_string_literal: true

require "rails_helper"

describe PurchaseItem do
  describe "shipped_at" do
    let(:company) { create(:shipping_company) }
    let(:shipped_at) { Time.zone.local(2026, 1, 1, 10) }
    let!(:item) { travel_to(shipped_at) { create(:purchase_item, tracking_number: "TRK-1", shipping_company: company) } }

    it "is nil without a tracking number" do
      expect(create(:purchase_item, tracking_number: nil).shipped_at).to be_nil
    end

    it "is the time the tracking number was set" do
      expect(item.shipped_at).to eq(shipped_at)
    end

    it "moves to the time the tracking number changed" do
      changed_at = Time.zone.local(2026, 2, 1, 10)
      travel_to(changed_at) { item.update!(tracking_number: "TRK-2") }

      expect(item.reload.shipped_at).to eq(changed_at)
    end

    it "is cleared with the tracking number" do
      item.update!(tracking_number: nil, shipping_company: nil)

      expect(item.reload.shipped_at).to be_nil
    end

    it "is unchanged by edits that keep the tracking number, past the audit history limit" do
      travel_to(Time.zone.local(2026, 10, 22, 10)) do
        110.times { |index| item.update!(weight: index + 1) }
      end

      expect(item.reload.shipped_at).to eq(shipped_at)
    end

    it "takes an explicit value over the automatic stamp" do
      explicit = Time.zone.local(2025, 12, 24)
      item.update!(tracking_number: "TRK-2", shipped_at: explicit)

      expect(item.reload.shipped_at).to eq(explicit)
    end

    it "ignores a value that is the same day as the stored one" do
      item.update!(shipped_at: shipped_at.to_date.iso8601, weight: 3)

      expect(item.reload.shipped_at).to eq(shipped_at)
    end

    it "can be cleared while the tracking number stays" do
      item.update!(shipped_at: "")

      expect(item.reload.shipped_at).to be_nil
    end
  end

  describe "#cost" do
    let(:purchase) { create(:purchase, item_price: 50.0) }
    let(:purchase_item) { create(:purchase_item, purchase:, shipping_cost: 10.0) }

    it "calculates cost including item price and shipping" do
      expect(purchase_item.cost).to eq(60.0)
    end
  end

  describe "#update_purchase_shipping_total callback" do
    let(:purchase) { create(:purchase, shipping_total: 0) }

    describe "when purchase_item is created" do
      it "adds shipping_cost to purchase.shipping_total" do
        create(:purchase_item, purchase:, shipping_cost: 15.0)
        expect(purchase.reload.shipping_total).to eq(15.0)
      end

      it "accumulates shipping_cost from multiple items" do
        create(:purchase_item, purchase:, shipping_cost: 10.0)
        create(:purchase_item, purchase:, shipping_cost: 5.0)
        expect(purchase.reload.shipping_total).to eq(15.0)
      end
    end

    describe "when purchase_item is destroyed" do
      let!(:purchase_item) { create(:purchase_item, purchase:, shipping_cost: 20.0) }

      it "subtracts shipping_cost from purchase.shipping_total" do
        purchase_item.destroy

        expect(purchase.reload.shipping_total).to eq(0)
      end
    end

    describe "when shipping_cost is updated" do
      let!(:purchase_item) { create(:purchase_item, purchase:, shipping_cost: 10.0) }

      it "updates purchase.shipping_total with the difference" do
        purchase_item.update!(shipping_cost: 25.0)

        expect(purchase.reload.shipping_total).to eq(25.0)
      end

      it "handles decreasing shipping_cost" do
        purchase_item.update!(shipping_cost: 5.0)

        expect(purchase.reload.shipping_total).to eq(5.0)
      end
    end

    describe "when shipping_cost is zero" do
      it "does not change purchase.shipping_total" do
        create(:purchase_item, purchase:, shipping_cost: 0)
        expect(purchase.reload.shipping_total).to eq(0)
      end
    end

    describe "when purchase_item is reassigned to a different purchase" do
      let(:new_purchase) { create(:purchase, shipping_total: 0) }
      let!(:purchase_item) { create(:purchase_item, purchase:, shipping_cost: 12.0) }

      it "moves shipping_cost from the old purchase's total to the new purchase's total" do
        purchase_item.update!(purchase_id: new_purchase.id)

        expect(purchase.reload.shipping_total).to eq(0)
        expect(new_purchase.reload.shipping_total).to eq(12.0)
      end

      it "uses the pre-change shipping_cost for the old purchase when both change in the same save" do
        purchase_item.update!(purchase_id: new_purchase.id, shipping_cost: 20.0)

        expect(purchase.reload.shipping_total).to eq(0)
        expect(new_purchase.reload.shipping_total).to eq(20.0)
      end
    end
  end
end
