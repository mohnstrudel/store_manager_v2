# frozen_string_literal: true

require "rails_helper"

RSpec.describe VariantImportConflict do
  let(:product) { create(:product) }

  describe ".record!" do
    it "updates the existing row for the same Shopify variant instead of adding another" do
      create(:variant_import_conflict, product:, store_id: "gid://shopify/ProductVariant/1", sku: "old")

      expect {
        described_class.record!(store_id: "gid://shopify/ProductVariant/1", product:, sku: "new", options: [])
      }.not_to change(described_class, :count)
      expect(described_class.sole.sku).to eq("new")
    end
  end

  describe ".keep_only!" do
    it "removes only this product's conflicts for Shopify variants outside the given ids" do
      kept = create(:variant_import_conflict, product:)
      create(:variant_import_conflict, product:)
      other_products = create(:variant_import_conflict)

      described_class.keep_only!(product, [kept.store_id])

      expect(described_class.all).to contain_exactly(kept, other_products)
    end
  end

  it "is removed with its product" do
    create(:variant_import_conflict, product:)

    expect { product.destroy! }.to change(described_class, :count).by(-1)
  end
end
