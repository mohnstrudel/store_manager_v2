require "rails_helper"

RSpec.describe Shopify::ProductParser do
  describe "#parse" do
    let(:api_product) do
      {
        "id" => "gid://shopify/Product/12345",
        "title" => "Stellar Blade - Eve | 1:4 Resin Statue | Light and Dust Studio",
        "handle" => "stellar-blade-eve-statue",
        "images" => {
          "edges" => [
            {"node" => {"src" => "https://example.com/image1.jpg"}},
            {"node" => {"src" => "https://example.com/image2.jpg"}}
          ]
        },
        "variants" => {
          "edges" => [
            {
              "node" => {
                "id" => "gid://shopify/ProductVariant/67890",
                "title" => "Regular",
                "selectedOptions" => [
                  {"name" => "Version", "value" => "Regular"}
                ]
              }
            }
          ]
        }
      }
    end

    let(:parser) { described_class.new(api_product: api_product) }

    it "parses product data correctly" do
      allow(parser).to receive(:parse_product_title).and_return(
        ["Eve", "Stellar Blade", "1:4", "Statue", "Light and Dust Studio"]
      )

      result = parser.parse

      expect(result).to include(
        shopify_id: "gid://shopify/Product/12345",
        store_link: "stellar-blade-eve-statue",
        title: "Eve",
        franchise: "Stellar Blade",
        size: "1:4",
        shape: "Statue",
        brand: "Light and Dust Studio"
      )

      expect(result[:images]).to eq([
        {"src" => "https://example.com/image1.jpg"},
        {"src" => "https://example.com/image2.jpg"}
      ])

      expect(result[:variations]).to eq([
        {
          id: "gid://shopify/ProductVariant/67890",
          title: "Regular",
          options: [
            {"name" => "Version", "value" => "Regular"}
          ]
        }
      ])
    end

    it "returns nil if product is blank" do
      parser = described_class.new(api_product: {})
      expect(parser.parse).to be_nil
    end
  end

  describe "#parse_product_title" do
    it "parses a standard product title format" do
      parser = described_class.new(title: "Stellar Blade - Eve | 1:4 Resin Statue | von Light and Dust Studio")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Eve")
      expect(franchise).to eq("Stellar Blade")
      expect(size).to eq("1:4")
      expect(shape).to eq("Statue")
      expect(brand).to eq("Light And Dust Studio")
    end

    it "handles titles without size or brand" do
      parser = described_class.new(title: "Elden Ring - Malenia | Resin Statue")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Malenia")
      expect(franchise).to eq("Elden Ring")
      expect(size).to be_nil
      expect(shape).to eq("Statue")
      expect(brand).to be_nil
    end

    it "handles titles with only franchise" do
      parser = described_class.new(title: "Elden Ring")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Elden Ring")
      expect(franchise).to eq("Elden Ring")
      expect(size).to be_nil
      expect(shape).to eq("Statue")
      expect(brand).to be_nil
    end
  end
end
