# frozen_string_literal: true
require "rails_helper"

RSpec.describe Shopify::ProductParser do
  describe "#parse" do
    let(:api_item) do
      {
        "id" => "gid://shopify/Product/12345",
        "title" => "Stellar Blade - Eve | 1:4 Resin Statue | Light and Dust Studio",
        "handle" => "stellar-blade-eve-statue",
        "media" => {
          "nodes" => [
            {
              "id" => "gid://shopify/MediaImage/123",
              "alt" => "Test image 1",
              "image" => {"url" => "https://example.com/image1.jpg"},
              "updatedAt" => "2024-01-01T00:00:00Z"
            },
            {
              "id" => "gid://shopify/MediaImage/456",
              "alt" => "Test image 2",
              "image" => {"url" => "https://example.com/image2.jpg"},
              "updatedAt" => "2024-01-01T01:00:00Z"
            }
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

    let(:parser) { described_class.new(api_item: api_item) }

    it "parses product data correctly" do # rubocop:todo RSpec/MultipleExpectations
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

      expect(result[:media]).to eq([
        {
          id: "gid://shopify/MediaImage/123",
          alt: "Test image 1",
          url: "https://example.com/image1.jpg",
          updated_at: "2024-01-01T00:00:00Z",
          position: 1
        },
        {
          id: "gid://shopify/MediaImage/456",
          alt: "Test image 2",
          url: "https://example.com/image2.jpg",
          updated_at: "2024-01-01T01:00:00Z",
          position: 2
        }
      ])

      expect(result[:editions]).to eq([
        {
          id: "gid://shopify/ProductVariant/67890",
          title: "Regular",
          options: [
            {"name" => "Version", "value" => "Regular"}
          ]
        }
      ])
    end

    it "handles missing variants" do
      product_without_variants = api_item.deep_dup
      product_without_variants["variants"] = {"edges" => []}

      parser = described_class.new(api_item: product_without_variants)
      allow(parser).to receive(:parse_product_title).and_return(
        ["Eve", "Stellar Blade", "1:4", "Statue", "Light and Dust Studio"]
      )

      result = parser.parse
      expect(result[:editions]).to be_empty
    end

    it "handles missing images" do
      product_without_images = api_item.deep_dup
      product_without_images["media"] = {"nodes" => []}

      parser = described_class.new(api_item: product_without_images)
      allow(parser).to receive(:parse_product_title).and_return(
        ["Eve", "Stellar Blade", "1:4", "Statue", "Light and Dust Studio"]
      )

      result = parser.parse
      expect(result[:media]).to be_empty
    end

    it "raises error when api_item is not a Hash" do
      expect { described_class.new(api_item: nil).parse }.to raise_error(NoMethodError)
    end

    it "raises error when api_item is blank" do
      expect { described_class.new(api_item: {}).parse }.to raise_error(ArgumentError, "api_item cannot be blank")
    end
  end

  describe "#parse_product_title" do
    it "parses a standard product title format" do # rubocop:todo RSpec/MultipleExpectations
      parser = described_class.new(title: "Stellar Blade - Eve | 1:4 Resin Statue | von Light and Dust Studio")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Eve")
      expect(franchise).to eq("Stellar Blade")
      expect(size).to eq("1:4")
      expect(shape).to eq("Statue")
      expect(brand).to eq("Light And Dust Studio")
    end

    it "handles titles without size or brand" do # rubocop:todo RSpec/MultipleExpectations
      parser = described_class.new(title: "Elden Ring - Malenia | Resin Statue")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Malenia")
      expect(franchise).to eq("Elden Ring")
      expect(size).to be_nil
      expect(shape).to eq("Statue")
      expect(brand).to be_nil
    end

    it "handles titles with only franchise" do # rubocop:todo RSpec/MultipleExpectations
      parser = described_class.new(title: "Elden Ring")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Elden Ring")
      expect(franchise).to eq("Elden Ring")
      expect(size).to be_nil
      expect(shape).to eq("Statue")
      expect(brand).to be_nil
    end

    it "handles titles with bust shape" do # rubocop:todo RSpec/MultipleExpectations
      parser = described_class.new(title: "Elden Ring - Malenia | 1:4 Resin Bust")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Malenia")
      expect(franchise).to eq("Elden Ring")
      expect(size).to eq("1:4")
      expect(shape).to eq("Bust")
      expect(brand).to be_nil
    end

    it "handles titles with special characters" do # rubocop:todo RSpec/MultipleExpectations
      parser = described_class.new(title: "Elden Ring - Malenia, Blade of Miquella | 1:4 Resin Statue")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Malenia, Blade Of Miquella")
      expect(franchise).to eq("Elden Ring")
      expect(size).to eq("1:4")
      expect(shape).to eq("Statue")
      expect(brand).to be_nil
    end

    it "handles titles with multiple brands" do # rubocop:todo RSpec/MultipleExpectations
      parser = described_class.new(title: "Elden Ring - Malenia | 1:4 Resin Statue | Prime 1 Studio & Gecco")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Malenia")
      expect(franchise).to eq("Elden Ring")
      expect(size).to eq("1:4")
      expect(shape).to eq("Statue")
      expect(brand).to eq("Prime 1 Studio & Gecco")
    end

    it "raises error when title is not a String" do
      expect { described_class.new(title: nil).parse_product_title }.to raise_error(ArgumentError, "Product title cannot be blank")
    end

    it "raises error when title is blank" do
      expect { described_class.new(title: "").parse_product_title }.to raise_error(ArgumentError, "Product title cannot be blank")
    end

    it "handles titles with 'Bunny Girl' character type" do # rubocop:todo RSpec/MultipleExpectations
      parser = described_class.new(title: "My Dress-Up Darling - Bunny Girl Kitagawa Marin | 1:6 Resin Statue | by BGA Studio")

      title, franchise, size, shape, brand = parser.parse_product_title

      expect(title).to eq("Bunny Girl Kitagawa Marin")
      expect(franchise).to eq("My Dress-Up Darling")
      expect(size).to eq("1:6")
      expect(shape).to eq("Statue")
      expect(brand).to eq("BGA Studio")
    end
  end
end
