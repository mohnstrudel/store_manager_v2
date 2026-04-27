# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Shopify::Parser do
  let(:api_order) do
    {
      "id" => "gid://shopify/Order/12345",
      "createdAt" => "2023-01-01T12:00:00Z",
      "updatedAt" => "2023-01-02T12:00:00Z",
      "cancelledAt" => nil,
      "cancelReason" => nil,
      "closed" => false,
      "closedAt" => nil,
      "confirmed" => true,
      "displayFinancialStatus" => "PAID",
      "displayFulfillmentStatus" => "UNFULFILLED",
      "note" => "Customer note",
      "returnStatus" => nil,
      "totalDiscountsSet" => {"shopMoney" => {"amount" => "10.00"}},
      "totalPriceSet" => {"shopMoney" => {"amount" => "100.00"}},
      "totalShippingPriceSet" => {"shopMoney" => {"amount" => "5.00"}},
      "email" => "customer@example.com",
      "shippingAddress" => {
        "address1" => "123 Main St",
        "address2" => "Apt 4B",
        "city" => "New York",
        "company" => "Acme Inc",
        "country" => "United States",
        "zip" => "10001"
      },
      "customer" => {
        "id" => "gid://shopify/Customer/67890",
        "firstName" => "John",
        "lastName" => "Doe",
        "defaultPhoneNumber" => {"phoneNumber" => "555-1234"},
        "defaultEmailAddress" => {"emailAddress" => "customer@example.com"},
        "createdAt" => "2023-01-01T11:00:00Z",
        "updatedAt" => "2023-01-02T11:00:00Z"
      },
      "lineItems" => {
        "nodes" => [
          {
            "id" => "gid://shopify/LineItem/111",
            "title" => "Stellar Blade - Eve | 1:4 Resin Statue",
            "quantity" => 1,
            "originalTotalSet" => {"shopMoney" => {"amount" => "95.00"}},
            "variantTitle" => "Regular",
            "variant" => {
              "id" => "gid://shopify/ProductVariant/222",
              "product" => {
                "id" => "gid://shopify/Product/333"
              }
            },
            "product" => {
              "id" => "gid://shopify/Product/333",
              "title" => "Stellar Blade - Eve | 1:4 Resin Statue | Light and Dust Studio",
              "handle" => "stellar-blade-eve-statue",
              "images" => {"edges" => []},
              "variants" => {"edges" => []}
            }
          }
        ]
      }
    }
  end

  before do
    # Stub Product::Shopify::Parser to return a hash with shopify_id key
    # This prevents recursive parsing
    allow(Product::Shopify::Parser).to receive(:parse).and_call_original
    allow(Product::Shopify::Parser).to receive(:parse).with(
      hash_including("id" => "gid://shopify/Product/333")
    ).and_return(
      {
        store_id: "gid://shopify/Product/333",
        title: "Eve",
        franchise: "Stellar Blade",
        editions: []
      }
    )
  end

  describe ".parse" do
    context "when payload is already parsed (has store_id key)" do
      let(:already_parsed) do
        {
          store_id: "gid://shopify/Order/12345",
          status: "pre-ordered"
        }
      end

      it "returns the payload as-is" do
        result = described_class.parse(already_parsed)
        expect(result).to eq(already_parsed)
      end
    end

    context "when parsing Shopify API payload" do
      it "raises ArgumentError if payload is blank" do
        expect { described_class.parse({}) }.to raise_error(ArgumentError, "Payload cannot be blank")
      end

      it "handles cancelled orders" do
        cancelled_order = api_order.deep_dup
        cancelled_order["cancelledAt"] = "2023-01-03T12:00:00Z"
        cancelled_order["cancelReason"] = "CUSTOMER"
        cancelled_order["displayFinancialStatus"] = "REFUNDED"
        cancelled_order["displayFulfillmentStatus"] = "UNFULFILLED"

        result = described_class.parse(cancelled_order)

        expect(result[:sale][:cancelled_at]).to eq(DateTime.parse("2023-01-03T12:00:00Z"))
        expect(result[:sale][:cancel_reason]).to eq("CUSTOMER")
        expect(result[:sale][:status]).to eq("cancelled")
      end

      it "handles completed orders" do
        completed_order = api_order.deep_dup
        completed_order["displayFinancialStatus"] = "PAID"
        completed_order["displayFulfillmentStatus"] = "FULFILLED"

        result = described_class.parse(completed_order)

        expect(result[:sale][:status]).to eq("completed")
      end

      it "handles partially paid orders" do
        partially_paid_order = api_order.deep_dup
        partially_paid_order["displayFinancialStatus"] = "PARTIALLY_PAID"

        result = described_class.parse(partially_paid_order)

        expect(result[:sale][:status]).to eq("partially-paid")
      end

      it "handles processing orders" do
        processing_order = api_order.deep_dup
        processing_order["displayFinancialStatus"] = "PENDING"

        result = described_class.parse(processing_order)

        expect(result[:sale][:status]).to eq("processing")
      end

      it "downcases customer email" do
        uppercase_email_order = api_order.deep_dup
        uppercase_email_order["email"] = "CUSTOMER@EXAMPLE.COM"

        result = described_class.parse(uppercase_email_order)

        expect(result[:customer][:email]).to eq("customer@example.com")
      end

      it "handles missing shipping address" do
        order_without_address = api_order.deep_dup
        order_without_address["shippingAddress"] = nil

        result = described_class.parse(order_without_address)

        expect(result[:sale]).to include(
          address_1: nil,
          address_2: nil,
          city: nil,
          company: nil,
          country: nil,
          postcode: nil
        )
      end

      it "handles missing variant data" do
        order_without_variant = api_order.deep_dup
        order_without_variant["lineItems"]["nodes"].first["variant"] = nil

        result = described_class.parse(order_without_variant)

        expect(result[:sale_items].first).to include(
          edition_store_id: nil,
          product_store_id: "gid://shopify/Product/333"
        )
      end

      it "handles missing product data" do
        order_without_product = api_order.deep_dup
        order_without_product["lineItems"]["nodes"].first["product"] = nil

        result = described_class.parse(order_without_product)

        expect(result[:sale_items].first[:product]).to be_nil
      end

      it "parses product data correctly" do
        allow(Product::Shopify::Parser).to receive(:parse).and_return(
          {
            store_id: "gid://shopify/Product/333",
            title: "Eve",
            franchise: "Stellar Blade",
            editions: [{
              id: "gid://shopify/ProductVariant/222",
              title: "Regular"
            }]
          }
        )

        result = described_class.parse(api_order)

        expect(result[:sale_items].first[:product]).to include(
          store_id: "gid://shopify/Product/333",
          title: "Eve",
          franchise: "Stellar Blade"
        )
      end

      it "stamps the known product_store_id onto parsed product payloads" do
        allow(Product::Shopify::Parser).to receive(:parse).and_return(
          {
            title: "Eve",
            franchise: "Stellar Blade",
            editions: []
          }
        )

        result = described_class.parse(api_order)

        expect(result[:sale_items].first[:product]).to include(
          store_id: "gid://shopify/Product/333",
          title: "Eve"
        )
      end

      it "handles missing customer data" do
        order_without_customer = api_order.deep_dup
        order_without_customer["customer"] = nil
        order_without_customer["email"] = "customer@example.com"

        result = described_class.parse(order_without_customer)

        expect(result[:customer]).to include(
          email: "customer@example.com"
        )

        expect(result[:customer][:store_info]).to be_nil
      end

      it "handles missing line items" do
        order_without_items = api_order.deep_dup
        order_without_items["lineItems"] = {"nodes" => []}

        result = described_class.parse(order_without_items)

        expect(result[:sale_items]).to be_empty
      end

      it "handles missing dates" do
        order_without_dates = api_order.deep_dup
        order_without_dates["createdAt"] = nil
        order_without_dates["updatedAt"] = nil

        result = described_class.parse(order_without_dates)

        expect(result[:sale][:shopify_created_at]).to be_nil
        expect(result[:store_info][:ext_created_at]).to be_nil
        expect(result[:store_info][:ext_updated_at]).to be_nil
      end

      it "handles missing customer timestamps" do
        order_without_customer_dates = api_order.deep_dup
        order_without_customer_dates["customer"]["createdAt"] = nil
        order_without_customer_dates["customer"]["updatedAt"] = nil

        result = described_class.parse(order_without_customer_dates)

        expect(result[:customer][:store_info][:ext_created_at]).to be_nil
        expect(result[:customer][:store_info][:ext_updated_at]).to be_nil
      end

      it "raises error for invalid datetime format" do
        invalid_date_order = api_order.deep_dup
        invalid_date_order["createdAt"] = "invalid-date"

        expect { described_class.parse(invalid_date_order) }.to raise_error(ArgumentError, "Invalid datetime format: invalid-date")
      end
    end
  end
end
