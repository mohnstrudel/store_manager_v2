# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::ShopifyParser do
  describe ".parse" do
    context "when payload is already parsed (has store_id key)" do
      let(:already_parsed) do
        {
          store_id: "gid://shopify/Product/12345",
          title: "Test"
        }
      end

      it "returns the payload as-is" do
        result = described_class.parse(already_parsed)
        expect(result).to eq(already_parsed)
      end
    end

    context "when parsing Shopify API payload" do
      let(:api_payload) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Stellar Blade - Eve | 1:4 Resin Statue | by Prime 1 Studio",
          "handle" => "stellar-blade-eve-statue",
          "createdAt" => "2024-01-01T00:00:00Z",
          "updatedAt" => "2024-01-15T00:00:00Z",
          "variants" => {
            "edges" => [
              {
                "node" => {
                  "id" => "gid://shopify/ProductVariant/67890",
                  "title" => "Regular",
                  "sku" => "SB-EVE-001",
                  "selectedOptions" => [
                    {"name" => "Version", "value" => "Regular"}
                  ]
                }
              },
              {
                "node" => {
                  "id" => "gid://shopify/ProductVariant/67891",
                  "title" => "Exclusive",
                  "sku" => "SB-EVE-001-EX",
                  "selectedOptions" => [
                    {"name" => "Version", "value" => "Exclusive"}
                  ]
                }
              }
            ]
          },
          "media" => {
            "nodes" => [
              {
                "id" => "gid://shopify/MediaImage/123",
                "alt" => "Front view",
                "image" => {"url" => "https://example.com/image1.jpg"},
                "createdAt" => "2024-01-01T00:00:00Z",
                "updatedAt" => "2024-01-02T00:00:00Z"
              },
              {
                "id" => "gid://shopify/MediaImage/456",
                "alt" => "Side view",
                "image" => {"url" => "https://example.com/image2.jpg"},
                "createdAt" => "2024-01-01T00:00:00Z",
                "updatedAt" => "2024-01-02T00:00:00Z"
              }
            ]
          }
        }
      end

      it "parses product basic data correctly" do
        result = described_class.parse(api_payload)

        expect(result).to include(
          store_id: "gid://shopify/Product/12345",
          store_link: "stellar-blade-eve-statue",
          title: "Eve",
          franchise: "Stellar Blade",
          size: "1:4",
          shape: "Statue",
          brand: "Prime 1 Studio"
        )
      end

      it "parses media with positions and timestamps" do
        result = described_class.parse(api_payload)

        expect(result[:media]).to eq([
          {
            id: "gid://shopify/MediaImage/123",
            alt: "Front view",
            url: "https://example.com/image1.jpg",
            position: 0,
            store_info: {
              ext_created_at: "2024-01-01T00:00:00Z",
              ext_updated_at: "2024-01-02T00:00:00Z"
            }
          },
          {
            id: "gid://shopify/MediaImage/456",
            alt: "Side view",
            url: "https://example.com/image2.jpg",
            position: 1,
            store_info: {
              ext_created_at: "2024-01-01T00:00:00Z",
              ext_updated_at: "2024-01-02T00:00:00Z"
            }
          }
        ])
      end

      it "parses editions with all variant data" do
        result = described_class.parse(api_payload)

        expect(result[:editions]).to eq([
          {
            id: "gid://shopify/ProductVariant/67890",
            title: "Regular",
            sku: "SB-EVE-001",
            options: [{"name" => "Version", "value" => "Regular"}]
          },
          {
            id: "gid://shopify/ProductVariant/67891",
            title: "Exclusive",
            sku: "SB-EVE-001-EX",
            options: [{"name" => "Version", "value" => "Exclusive"}]
          }
        ])
      end

      it "parses store info timestamps" do
        result = described_class.parse(api_payload)

        expect(result[:store_info]).to eq(
          {
            ext_created_at: "2024-01-01T00:00:00Z",
            ext_updated_at: "2024-01-15T00:00:00Z"
          }
        )
      end

      it "extracts SKU from first variant" do
        result = described_class.parse(api_payload)
        expect(result[:sku]).to eq("SB-EVE-001")
      end
    end

    context "with minimal payload (no media, no variants, no brand)" do
      let(:minimal_payload) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Simple Figure",
          "handle" => "simple-figure",
          "variants" => {"edges" => []},
          "media" => nil
        }
      end

      it "handles missing data gracefully" do # rubocop:todo RSpec/MultipleExpectations
        result = described_class.parse(minimal_payload)

        expect(result[:store_id]).to eq("gid://shopify/Product/12345")
        expect(result[:title]).to eq("Simple Figure")
        expect(result[:franchise]).to eq("Simple Figure")
        expect(result[:media] || []).to eq([])
        expect(result[:editions] || []).to eq([])
        expect(result[:brand]).to be_nil
        expect(result[:size]).to be_nil
      end

      it "generates a SKU when none exists in variants" do
        result = described_class.parse(minimal_payload)
        expect(result[:sku]).to match(/^simple-figure-[a-zA-Z0-9]{4}$/)
      end
    end

    context "when title equals franchise" do
      let(:same_title_payload) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Stellar Blade",
          "handle" => "stellar-blade",
          "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => "SKU-001", "title" => "Default", "selectedOptions" => []}}]},
          "media" => nil
        }
      end

      it "sets both title and franchise to the same value" do # rubocop:todo RSpec/MultipleExpectations
        result = described_class.parse(same_title_payload)
        expect(result[:title]).to eq("Stellar Blade")
        expect(result[:franchise]).to eq("Stellar Blade")
      end
    end

    context "with Bust shape" do
      let(:bust_payload) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Character - Head | 1:4 Resin Bust",
          "handle" => "character-head-bust",
          "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => "SKU-001", "title" => "Default", "selectedOptions" => []}}]},
          "media" => nil
        }
      end

      it "correctly parses Bust shape" do
        result = described_class.parse(bust_payload)
        expect(result[:shape]).to eq("Bust")
      end
    end

    context "without explicit size in title" do
      let(:no_size_payload) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Character - Statue",
          "handle" => "character-statue",
          "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => "SKU-001", "title" => "Default", "selectedOptions" => []}}]},
          "media" => nil
        }
      end

      it "sets size to nil" do
        result = described_class.parse(no_size_payload)
        expect(result[:size]).to be_nil
      end
    end

    context "with variants but no SKU" do
      let(:no_sku_payload) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Test Product",
          "handle" => "test-product",
          "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => nil, "title" => "Default", "selectedOptions" => []}}]},
          "media" => nil
        }
      end

      it "generates a unique SKU" do
        result = described_class.parse(no_sku_payload)
        expect(result[:sku]).to match(/^test-product-[a-zA-Z0-9]{4}$/)
      end
    end

    context "with variant having selectedOptions" do
      let(:options_payload) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Test Product",
          "handle" => "test-product",
          "variants" => {
            "edges" => [
              {
                "node" => {
                  "id" => "gid://shopify/ProductVariant/1",
                  "title" => "Regular",
                  "sku" => "TEST-001",
                  "selectedOptions" => [
                    {"name" => "Color", "value" => "Red"},
                    {"name" => "Size", "value" => "Large"}
                  ]
                }
              }
            ]
          },
          "media" => nil
        }
      end

      it "parses variant options correctly" do
        result = described_class.parse(options_payload)
        expect(result[:editions].first[:options]).to eq([
          {"name" => "Color", "value" => "Red"},
          {"name" => "Size", "value" => "Large"}
        ])
      end
    end
  end
end
