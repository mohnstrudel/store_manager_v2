# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Exporting do
  describe "#shopify_payload" do
    let(:franchise) { create(:franchise, title: "Studio Ghibli") }
    let(:shape) { create(:shape, title: "Statue") }
    let(:brand) { create(:brand, title: "Zuoban Studio") }
    let(:product) { create(:product, title: "Spirited Away", franchise:, shape:) }

    before do
      product.brands << brand
      product.shopify_info.update(tag_list: ["statue", "premium"])
    end

    it "returns serialized product data" do
      expect(product.shopify_payload).to be_a(Hash)
    end

    it "returns title as a string" do
      expect(product.shopify_payload[:title]).to be_a(String)
    end

    it "serializes product title" do
      expect(product.shopify_payload[:title]).to eq("Studio Ghibli - Spirited Away | Resin Statue | by Zuoban Studio")
    end

    it "returns title and tags when description is blank" do
      expect(product.shopify_payload.keys).to eq([:title, :tags])
    end

    it "includes descriptionHtml and tags when product has description" do
      html_description = "<p>This is a <strong>premium</strong> collectible figure.</p>"
      product.update(description: html_description)

      expect(product.shopify_payload.keys).to eq([:title, :descriptionHtml, :tags])
    end

    it "includes descriptionHtml content when product has description" do
      html_description = "<p>This is a <strong>premium</strong> collectible figure.</p>"
      product.update(description: html_description)

      expect(product.shopify_payload[:descriptionHtml]).to eq(html_description)
    end

    it "does not include descriptionHtml when description is nil" do
      expect(product.shopify_payload.key?(:descriptionHtml)).to be false
    end

    it "does not include descriptionHtml when description is empty string" do
      product.update(description: "")

      expect(product.shopify_payload.key?(:descriptionHtml)).to be false
    end

    it "handles multiple brands" do
      second_brand = create(:brand, title: "Another Studio")
      product.brands << second_brand

      expect(product.shopify_payload[:title]).to include("by Zuoban Studio, Another Studio")
    end

    it "strips whitespace from description HTML" do
      html_description = "  <p>This is a <strong>premium</strong> collectible figure.</p>  "
      product.update(description: html_description)

      expect(product.shopify_payload[:descriptionHtml]).to eq("<p>This is a <strong>premium</strong> collectible figure.</p>")
    end

    it "handles product with no brands" do
      product.brands.clear

      expect(product.shopify_payload[:title]).to eq("Studio Ghibli - Spirited Away | Resin Statue | by ")
    end

    it "returns hash with symbol keys" do
      expect(product.shopify_payload.keys).to all(be_a(Symbol))
    end

    it "includes tags from Shopify StoreInfo" do
      product.shopify_info.update!(tag_list: "statue, premium")

      expect(product.shopify_payload[:tags].to_a).to eq(["statue", "premium"])
    end

    it "returns empty array for tags when product has no Shopify StoreInfo" do
      product_without_store_info = create(:product, title: "No Store Info", franchise:, shape:)
      product_without_store_info.brands << brand
      product_without_store_info.store_infos.destroy_all

      expect(product_without_store_info.shopify_payload[:tags]).to eq([])
    end

    it "returns empty array for tags when Shopify StoreInfo has no tags" do
      product.shopify_info.update(tag_list: [])

      expect(product.shopify_payload[:tags]).to eq([])
    end
  end
end
