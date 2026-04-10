# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Parser do
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
          "descriptionHtml" => "<p>This is a <strong>premium</strong> collectible statue.</p>",
          "tags" => ["statue", "premium", "exclusive"],
          "createdAt" => "2024-01-01T00:00:00Z",
          "updatedAt" => "2024-01-15T00:00:00Z",
          "variants" => {
            "edges" => [
              {
                "node" => {
                  "id" => "gid://shopify/ProductVariant/67890",
                  "title" => "Regular",
                  "sku" => "SB-EVE-001",
                  "price" => "299.99",
                  "inventoryItem" => {
                    "id" => "gid://shopify/InventoryItem/111",
                    "unitCost" => {
                      "amount" => "150.00",
                      "currencyCode" => "EUR"
                    },
                    "measurement" => {
                      "weight" => {
                        "value" => 2.5
                      }
                    }
                  },
                  "createdAt" => "2024-01-01T00:00:00Z",
                  "updatedAt" => "2024-01-02T00:00:00Z",
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
                  "price" => "399.99",
                  "inventoryItem" => {
                    "id" => "gid://shopify/InventoryItem/222",
                    "unitCost" => {
                      "amount" => "200.00",
                      "currencyCode" => "EUR"
                    },
                    "measurement" => {
                      "weight" => {
                        "value" => 3.0
                      }
                    }
                  },
                  "createdAt" => "2024-01-01T00:00:00Z",
                  "updatedAt" => "2024-01-03T00:00:00Z",
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
          brand: "Prime 1 Studio",
          description: "<p>This is a <strong>premium</strong> collectible statue.</p>"
        )
      end

      it "parses descriptionHtml as description" do
        result = described_class.parse(api_payload)
        expect(result[:description]).to eq("<p>This is a <strong>premium</strong> collectible statue.</p>")
      end

      it "parses media with positions and timestamps" do
        result = described_class.parse(api_payload)

        expect(result[:media]).to eq([
          {
            key: "gid://shopify/MediaImage/123",
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
            key: "gid://shopify/MediaImage/456",
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
            store_id: "gid://shopify/ProductVariant/67890",
            title: "Regular",
            sku: "SB-EVE-001",
            selling_price: "299.99",
            purchase_cost: "150.00",
            weight: 2.5,
            options: [{name: "Version", value: "Regular"}],
            is_single_variant: false,
            store_info: {
              ext_created_at: "2024-01-01T00:00:00Z",
              ext_updated_at: "2024-01-02T00:00:00Z"
            }
          },
          {
            store_id: "gid://shopify/ProductVariant/67891",
            title: "Exclusive",
            sku: "SB-EVE-001-EX",
            selling_price: "399.99",
            purchase_cost: "200.00",
            weight: 3.0,
            options: [{name: "Version", value: "Exclusive"}],
            is_single_variant: false,
            store_info: {
              ext_created_at: "2024-01-01T00:00:00Z",
              ext_updated_at: "2024-01-03T00:00:00Z"
            }
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

      it "parses tags from the payload" do
        result = described_class.parse(api_payload)

        expect(result[:tags]).to eq(["statue", "premium", "exclusive"])
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

      it "excludes tags key when not provided (removed by compact_blank)" do
        result = described_class.parse(minimal_payload)
        expect(result.key?(:tags)).to be false
      end

      it "excludes description key when descriptionHtml is not provided" do
        result = described_class.parse(minimal_payload)
        expect(result.key?(:description)).to be false
      end
    end

    context "with empty descriptionHtml" do
      let(:empty_description_payload) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Test Product",
          "handle" => "test-product",
          "descriptionHtml" => "",
          "variants" => {"edges" => [{"node" => {"id" => "1", "sku" => "SKU-001", "title" => "Default", "selectedOptions" => []}}]},
          "media" => nil
        }
      end

      it "excludes description key when descriptionHtml is empty" do
        result = described_class.parse(empty_description_payload)
        expect(result.key?(:description)).to be false
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
              },
              {
                "node" => {
                  "id" => "gid://shopify/ProductVariant/2",
                  "title" => "Deluxe",
                  "sku" => "TEST-002",
                  "selectedOptions" => [
                    {"name" => "Color", "value" => "Blue"}
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
          {name: "Color", value: "Red"},
          {name: "Size", value: "Large"}
        ])
      end
    end

    context "with single variant product" do
      let(:single_variant_payload) do
        {
          "id" => "gid://shopify/Product/12345",
          "title" => "Test Product",
          "handle" => "test-product",
          "variants" => {
            "edges" => [
              {
                "node" => {
                  "id" => "gid://shopify/ProductVariant/1",
                  "title" => "Default Title",
                  "sku" => "TEST-001",
                  "price" => "199.99",
                  "inventoryItem" => {
                    "id" => "gid://shopify/InventoryItem/1",
                    "unitCost" => {
                      "amount" => "80.00",
                      "currencyCode" => "EUR"
                    },
                    "measurement" => {
                      "weight" => {
                        "value" => 1.5
                      }
                    }
                  },
                  "createdAt" => "2024-01-01T00:00:00Z",
                  "updatedAt" => "2024-01-02T00:00:00Z",
                  "selectedOptions" => [
                    {"name" => "Title", "value" => "Default Title"}
                  ]
                }
              }
            ]
          },
          "media" => nil
        }
      end

      it "sets is_single_variant flag to true" do
        result = described_class.parse(single_variant_payload)
        expect(result[:editions].first[:is_single_variant]).to be(true)
      end

      it "parses price, cost, and weight from inventory item" do
        result = described_class.parse(single_variant_payload)
        edition = result[:editions].first

        expect(edition[:selling_price]).to eq("199.99")
        expect(edition[:purchase_cost]).to eq("80.00")
        expect(edition[:weight]).to eq(1.5)
      end

      it "parses store_info timestamps from variant" do
        result = described_class.parse(single_variant_payload)
        edition = result[:editions].first

        expect(edition[:store_info]).to eq({
          ext_created_at: "2024-01-01T00:00:00Z",
          ext_updated_at: "2024-01-02T00:00:00Z"
        })
      end
    end

    context "with variant missing inventory item data" do
      let(:variant_without_inventory_payload) do
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
                  "price" => "99.99",
                  "selectedOptions" => [
                    {"name" => "Version", "value" => "Regular"}
                  ]
                }
              }
            ]
          },
          "media" => nil
        }
      end

      it "parses selling_price but omits missing purchase_cost and weight" do
        result = described_class.parse(variant_without_inventory_payload)
        edition = result[:editions].first

        expect(edition[:selling_price]).to eq("99.99")
        expect(edition.key?(:purchase_cost)).to be false
        expect(edition.key?(:weight)).to be false
      end
    end
  end
end
