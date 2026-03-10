# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::ShopifySerializer do
  describe ".for_export" do
    let(:franchise) { create(:franchise, title: "Studio Ghibli") }
    let(:shape) { create(:shape, title: "Statue") }
    let(:brand) { create(:brand, title: "Zuoban Studio") }
    let(:product) { create(:product, title: "Spirited Away", franchise: franchise, shape: shape) }

    before do
      product.brands << brand
      product.shopify_info.update(tag_list: ["statue", "premium"])
    end

    it "calls serialize on the instance" do
      serializer_instance = instance_double(described_class)

      allow(described_class).to receive(:new).and_return(serializer_instance)
      allow(serializer_instance).to receive(:serialize).and_return({})

      described_class.for_export(product)

      expect(serializer_instance).to have_received(:serialize)
    end

    it "returns serialized product data" do
      result = described_class.for_export(product)

      expect(result).to be_a(Hash)
    end

    it "returns title as a string" do
      result = described_class.for_export(product)

      expect(result[:title]).to be_a(String)
    end
  end

  describe "#initialize" do
    let(:product) { build(:product) }

    it "stores the product" do
      serializer = described_class.new(product)
      expect(serializer.instance_variable_get(:@product)).to eq(product)
    end
  end

  describe "#serialize" do
    let(:franchise) { create(:franchise, title: "Studio Ghibli") }
    let(:shape) { create(:shape, title: "Statue") }
    let(:brand) { create(:brand, title: "Zuoban Studio") }
    let(:product) { create(:product, title: "Spirited Away", franchise: franchise, shape: shape) }

    before do
      product.brands << brand
    end

    it "serializes product title" do
      serializer = described_class.new(product)
      result = serializer.serialize

      expect(result[:title]).to eq("Studio Ghibli - Spirited Away | Resin Statue | by Zuoban Studio")
    end

    it "returns title and tags in serialized output when description is blank" do
      serializer = described_class.new(product)
      result = serializer.serialize

      expect(result.keys).to eq([:title, :tags])
    end

    it "includes descriptionHtml and tags when product has description" do
      html_description = "<p>This is a <strong>premium</strong> collectible figure.</p>"
      product.update(description: html_description)

      result = described_class.for_export(product)

      expect(result.keys).to eq([:title, :descriptionHtml, :tags])
    end

    it "includes descriptionHtml content when product has description" do
      html_description = "<p>This is a <strong>premium</strong> collectible figure.</p>"
      product.update(description: html_description)

      result = described_class.for_export(product)

      expect(result[:descriptionHtml]).to eq(html_description)
    end

    it "does not include descriptionHtml when description is nil" do
      result = described_class.for_export(product)

      expect(result.key?(:descriptionHtml)).to be false
    end

    it "does not include descriptionHtml when description is empty string" do
      product.update(description: "")

      result = described_class.for_export(product)

      expect(result.key?(:descriptionHtml)).to be false
    end

    it "handles multiple brands" do
      second_brand = create(:brand, title: "Another Studio")
      product.brands << second_brand

      result = described_class.for_export(product)

      expect(result[:title]).to include("by Zuoban Studio, Another Studio")
    end

    it "strips whitespace from description HTML" do
      html_description = "  <p>This is a <strong>premium</strong> collectible figure.</p>  "
      product.update(description: html_description)

      result = described_class.for_export(product)

      expect(result[:descriptionHtml]).to eq("<p>This is a <strong>premium</strong> collectible figure.</p>")
    end

    it "handles product with no brands" do
      product.brands.clear

      result = described_class.for_export(product)

      expect(result[:title]).to eq("Studio Ghibli - Spirited Away | Resin Statue | by ")
    end

    it "returns hash with symbol keys" do
      result = described_class.for_export(product)

      expect(result.keys).to all(be_a(Symbol))
    end

    it "includes tags from Shopify StoreInfo" do
      product.shopify_info.tag_list = "statue, premium"
      product.shopify_info.save!
      product.shopify_info.reload

      result = described_class.for_export(product)

      expect(result[:tags].to_a).to eq(["statue", "premium"])
    end

    it "returns empty array for tags when product has no Shopify StoreInfo" do
      product_without_store_info = create(:product, title: "No Store Info", franchise: franchise, shape: shape)
      product_without_store_info.brands << brand

      result = described_class.for_export(product_without_store_info)

      expect(result[:tags]).to eq([])
    end

    it "returns empty array for tags when Shopify StoreInfo has no tags" do
      product.shopify_info.update(tag_list: [])

      result = described_class.for_export(product)

      expect(result[:tags]).to eq([])
    end
  end
end
