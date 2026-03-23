# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale do
  describe "#active?" do
    it "returns true for active statuses" do
      sale = create(:sale, status: described_class.active_status_names.first)

      expect(sale.active?).to be true
    end
  end

  describe "#completed?" do
    it "returns true for completed statuses" do
      sale = create(:sale, status: described_class.completed_status_names.first)

      expect(sale.completed?).to be true
    end
  end

  describe ".derive_status_from_shopify" do
    context "with fulfilled and paid" do
      it "returns completed" do
        expect(described_class.derive_status_from_shopify("FULFILLED", "PAID")).to eq("completed")
      end
    end

    context "with unfulfilled and paid" do
      it "returns pre-ordered" do
        expect(described_class.derive_status_from_shopify("UNFULFILLED", "PAID")).to eq("pre-ordered")
      end
    end

    context "with unfulfilled and pending" do
      it "returns processing" do
        expect(described_class.derive_status_from_shopify("UNFULFILLED", "PENDING")).to eq("processing")
      end
    end

    context "with unfulfilled and partially paid" do
      it "returns partially-paid" do
        expect(described_class.derive_status_from_shopify("UNFULFILLED", "PARTIALLY_PAID")).to eq("partially-paid")
      end
    end

    context "with fulfilled and refunded" do
      it "returns refunded" do
        expect(described_class.derive_status_from_shopify("FULFILLED", "REFUNDED")).to eq("refunded")
      end
    end

    context "with unfulfilled and refunded" do
      it "returns cancelled" do
        expect(described_class.derive_status_from_shopify("UNFULFILLED", "REFUNDED")).to eq("cancelled")
      end
    end

    context "with unknown status combination" do
      it "defaults to processing" do
        expect(described_class.derive_status_from_shopify("UNKNOWN", "UNKNOWN")).to eq("processing")
      end
    end
  end
end
