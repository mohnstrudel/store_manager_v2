# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::ShopifyParser do
  describe ".parse" do
    context "when payload is already parsed (has shopify_id key)" do
      let(:already_parsed) do
        {
          shopify_id: "gid://shopify/Product/12345",
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
          shopify_id: "gid://shopify/Product/12345",
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

        expect(result[:shopify_id]).to eq("gid://shopify/Product/12345")
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

  describe "#initialize" do
    it "stores the payload" do
      payload = {"id" => "123", "title" => "Test"}
      parser = described_class.new(payload)
      expect(parser.payload).to eq(payload)
    end
  end

  describe "#parse (instance method)" do
    let(:api_payload) do
      {
        "id" => "gid://shopify/Product/12345",
        "title" => "Test - Product | 1:4 Resin Statue",
        "handle" => "test-product",
        "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => "SKU", "title" => "Default", "selectedOptions" => []}}]},
        "media" => nil
      }
    end

    it "returns a hash with all parsed data" do # rubocop:todo RSpec/MultipleExpectations
      parser = described_class.new(api_payload)
      result = parser.parse

      expect(result).to be_a(Hash)
      expect(result).to have_key(:shopify_id)
      expect(result).to have_key(:title)
      expect(result).to have_key(:franchise)
    end
  end

  describe "private methods", :private do
    let(:api_payload) do
      {
        "id" => "gid://shopify/Product/12345",
        "title" => "Elden Ring - Malenia | 1:4 | Resin Statue | by Prime 1 Studio",
        "handle" => "test-product",
        "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => "SKU", "title" => "Default", "selectedOptions" => []}}]},
        "media" => nil
      }
    end

    let(:parser) { described_class.new(api_payload) }

    describe "#parse_shopify_title" do
      it "splits title into components" do
        parser.send(:parse_shopify_title)
        expect(parser.parsed_title).to eq(
          {
            brand: "Prime 1 Studio",
            franchise: "Elden Ring",
            shape: "Statue",
            size: "1:4",
            title: "Malenia"
          }
        )
      end

      context "with title without brand" do # rubocop:todo RSpec/NestedGroups
        let(:api_payload) do
          {
            "id" => "gid://shopify/Product/12345",
            "title" => "Elden Ring - Malenia | 1:4 Resin Statue",
            "handle" => "test-product",
            "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => "SKU", "title" => "Default", "selectedOptions" => []}}]},
            "media" => nil
          }
        end

        it "parses without brand" do
          parser.send(:parse_shopify_title)
          expect(parser.parsed_title[:brand]).to be_nil
        end
      end

      context "with title without size" do # rubocop:todo RSpec/NestedGroups
        let(:api_payload) do
          {
            "id" => "gid://shopify/Product/12345",
            "title" => "Elden Ring - Malenia | Resin Statue",
            "handle" => "test-product",
            "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => "SKU", "title" => "Default", "selectedOptions" => []}}]},
            "media" => nil
          }
        end

        it "parses without size" do
          parser.send(:parse_shopify_title)
          expect(parser.parsed_title[:size]).to be_nil
        end
      end
    end

    describe "#parse_sku" do
      it "extracts SKU from first variant" do
        parser.send(:parse_sku)
        expect(parser.parsed_sku).to eq("SKU")
      end

      context "when variant has no SKU" do # rubocop:todo RSpec/NestedGroups
        let(:api_payload) do
          {
            "id" => "gid://shopify/Product/12345",
            "title" => "Test Product",
            "handle" => "test-product",
            "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => nil, "title" => "Default", "selectedOptions" => []}}]},
            "media" => nil
          }
        end

        it "generates a SKU" do
          parser.send(:parse_sku)
          expect(parser.parsed_sku).to match(/^test-product-[a-zA-Z0-9]{4}$/)
        end
      end
    end

    describe "#parse_media" do
      let(:api_payload_with_media) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Test Product",
          "handle" => "test-product",
          "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => "SKU", "title" => "Default", "selectedOptions" => []}}]},
          "media" => {
            "nodes" => [
              {
                "id" => "gid://shopify/MediaImage/1",
                "alt" => "Test",
                "image" => {"url" => "https://example.com/image.jpg"},
                "createdAt" => "2024-01-01T00:00:00Z",
                "updatedAt" => "2024-01-01T00:00:00Z"
              }
            ]
          }
        }
      end

      let(:parser_with_media) { described_class.new(api_payload_with_media) }

      it "parses media nodes with positions" do
        parser_with_media.send(:parse_media)
        expect(parser_with_media.parsed_media).to eq([
          {
            id: "gid://shopify/MediaImage/1",
            alt: "Test",
            url: "https://example.com/image.jpg",
            position: 0,
            store_info: {
              ext_created_at: "2024-01-01T00:00:00Z",
              ext_updated_at: "2024-01-01T00:00:00Z"
            }
          }
        ])
      end

      context "when media is nil" do # rubocop:todo RSpec/NestedGroups
        it "returns empty array" do
          parser.send(:parse_media)
          expect(parser.parsed_media).to eq([])
        end
      end
    end

    describe "#parse_editions" do
      let(:api_payload_with_variants) do
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
                  "selectedOptions" => [{"name" => "Type", "value" => "Regular"}]
                }
              },
              {
                "node" => {
                  "id" => "gid://shopify/ProductVariant/2",
                  "title" => "Exclusive",
                  "sku" => "TEST-002",
                  "selectedOptions" => [{"name" => "Type", "value" => "Exclusive"}]
                }
              }
            ]
          },
          "media" => nil
        }
      end

      let(:parser_with_variants) { described_class.new(api_payload_with_variants) }

      it "parses variant edges into editions" do
        parser_with_variants.send(:parse_editions)
        expect(parser_with_variants.parsed_editions).to eq([
          {
            id: "gid://shopify/ProductVariant/1",
            title: "Regular",
            sku: "TEST-001",
            options: [{"name" => "Type", "value" => "Regular"}]
          },
          {
            id: "gid://shopify/ProductVariant/2",
            title: "Exclusive",
            sku: "TEST-002",
            options: [{"name" => "Type", "value" => "Exclusive"}]
          }
        ])
      end

      context "when variants is nil" do # rubocop:todo RSpec/NestedGroups
        let(:api_payload_no_variants) do
          {
            "id" => "gid://shopify/Product/12345",
            "title" => "Test Product",
            "handle" => "test-product",
            "variants" => nil,
            "media" => nil
          }
        end

        let(:parser_no_variants) { described_class.new(api_payload_no_variants) }

        it "returns empty array" do
          parser_no_variants.send(:parse_editions)
          expect(parser_no_variants.parsed_editions).to eq([])
        end
      end
    end
  end
end
