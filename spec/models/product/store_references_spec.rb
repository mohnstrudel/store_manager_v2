# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#build_full_title_with_shop_id" do
    it "combines the product title with Shopify and Woo ids" do
      product = create(:product, title: "Malenia")
      product.shopify_info.update!(store_id: "gid://shopify/Product/12345")
      product.woo_info.update!(store_id: "woo-67890")

      expect(product.build_full_title_with_shop_id).to eq("Studio Ghibli — Malenia | 12345 | woo-67890")
    end

    it "uses N/A when both store ids are blank" do
      product = create(:product, title: "Malenia")
      product.shopify_info.update!(store_id: nil)
      product.woo_info.update!(store_id: nil)

      expect(product.build_full_title_with_shop_id).to eq("Studio Ghibli — Malenia | N/A")
    end
  end

  describe "#build_shopify_url" do
    it "builds a Shopify product url when a slug is present" do
      product = create(:product)
      product.shopify_info.update!(slug: "test-product")

      expect(product.build_shopify_url).to eq("https://handsomecake.com/products/test-product")
    end

    it "falls back to the storefront root when slug is missing" do
      product = create(:product)
      product.shopify_info.update!(slug: nil)

      expect(product.build_shopify_url).to eq("https://handsomecake.com/")
    end
  end

  describe ".with_store_references" do
    it "eager loads store infos and orders by full_title" do
      older = create(:product, title: "Alpha")
      newer = create(:product, title: "Omega")

      relation = described_class.with_store_references.where(id: [older.id, newer.id]).to_a

      aggregate_failures do
        expect(relation.map(&:id)).to eq([older.id, newer.id].sort_by { |id| Product.find(id).full_title })
        expect(relation.first.association(:shopify_info).loaded?).to be true
        expect(relation.first.association(:woo_info).loaded?).to be true
      end
    end
  end
end
