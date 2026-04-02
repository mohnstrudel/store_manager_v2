# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchase do
  describe "#title" do
    it "includes the purchase id and product title" do
      purchase = create(:purchase)

      expect(purchase.title).to eq("Purchase #{purchase.id}: #{purchase.product.title}")
    end

    it "handles a missing product gracefully" do
      purchase = build(:purchase, product: nil)

      expect { purchase.title }.not_to raise_error
    end
  end

  describe "#full_title" do
    let(:purchase_date) { Date.new(2023, 1, 1) }
    let(:created_at) { DateTime.new(2023, 1, 2) }

    it "generates formatted title with supplier, product, and purchase_date" do
      purchase = create(:purchase)
      purchase.purchase_date = purchase_date

      expected_title = "#{purchase.supplier.title} | #{purchase.product.full_title} | 2023-01-01"
      expect(purchase.full_title).to eq(expected_title)
    end

    it "uses created_at when purchase_date is nil" do
      purchase = create(:purchase)
      purchase.purchase_date = nil
      purchase.created_at = created_at

      expected_title = "#{purchase.supplier.title} | #{purchase.product.full_title} | 2023-01-02"
      expect(purchase.full_title).to eq(expected_title)
    end

    it "handles nil dates gracefully" do
      purchase = create(:purchase)
      purchase.purchase_date = nil
      purchase.created_at = nil

      expected_title = "#{purchase.supplier.title} | #{purchase.product.full_title} | "
      expect(purchase.full_title).to eq(expected_title)
    end

    it "handles missing associations gracefully" do
      purchase = build(:purchase, supplier: nil, product: nil)

      expect { purchase.full_title }.not_to raise_error
    end
  end

  describe "#edition_title" do
    context "when edition is present" do
      let(:edition) { create(:edition) }
      let(:purchase) { create(:purchase, edition:) }

      it "returns edition title" do
        expect(purchase.edition_title).to eq(edition.title)
      end
    end

    context "when edition is nil" do
      let(:purchase) { create(:purchase, edition: nil) }

      it "returns '-'" do
        expect(purchase.edition_title).to eq("-")
      end
    end
  end
end
