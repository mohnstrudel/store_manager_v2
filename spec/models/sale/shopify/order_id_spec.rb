# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Shopify::OrderId do
  describe ".normalize" do
    it "normalizes Shopify GIDs and SEAL numeric IDs to the same value" do
      aggregate_failures do
        expect(described_class.normalize("gid://shopify/Order/123456")).to eq("123456")
        expect(described_class.normalize("123456")).to eq("123456")
        expect(described_class.normalize(123_456)).to eq("123456")
      end
    end

    it "rejects blank and non-order identifiers" do
      aggregate_failures do
        expect(described_class.normalize(nil)).to be_nil
        expect(described_class.normalize("")).to be_nil
        expect(described_class.normalize("order-123456")).to be_nil
      end
    end
  end
end
