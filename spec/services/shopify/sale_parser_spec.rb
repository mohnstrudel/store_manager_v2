require "rails_helper"

RSpec.describe Shopify::SaleParser do
  describe "#parse" do
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
        "totalDiscounts" => "10.00",
        "totalPrice" => "100.00",
        "totalShippingPrice" => "5.00",
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
          "phone" => "555-1234"
        },
        "lineItems" => {
          "nodes" => [
            {
              "id" => "gid://shopify/LineItem/111",
              "title" => "Stellar Blade - Eve | 1:4 Resin Statue",
              "quantity" => 1,
              "originalTotal" => "95.00",
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

    let(:parser) { described_class.new(api_item: api_order) }

    before do
      allow_any_instance_of(Shopify::ProductParser).to receive(:parse).and_return({
        shopify_id: "gid://shopify/Product/333",
        title: "Eve",
        franchise: "Stellar Blade"
      })
    end

    it "parses order data correctly" do
      result = parser.parse

      expect(result[:sale]).to include(
        shopify_id: "gid://shopify/Order/12345",
        address_1: "123 Main St",
        address_2: "Apt 4B",
        city: "New York",
        company: "Acme Inc",
        country: "United States",
        postcode: "10001",
        discount_total: "10.00",
        shipping_total: "5.00",
        total: "100.00",
        financial_status: "PAID",
        fulfillment_status: "UNFULFILLED",
        note: "Customer note",
        status: "pre-ordered",
        shopify_created_at: DateTime.parse("2023-01-01T12:00:00Z"),
        shopify_updated_at: DateTime.parse("2023-01-02T12:00:00Z")
      )

      expect(result[:customer]).to include(
        shopify_id: "gid://shopify/Customer/67890",
        email: "customer@example.com",
        first_name: "John",
        last_name: "Doe",
        phone: "555-1234"
      )

      expect(result[:sale_items].first).to include(
        shopify_id: "gid://shopify/LineItem/111",
        price: "95.00",
        qty: 1,
        edition_title: "Regular",
        shopify_edition_id: "gid://shopify/ProductVariant/222",
        shopify_product_id: "gid://shopify/Product/333",
        full_title: "Stellar Blade - Eve | 1:4 Resin Statue"
      )
    end

    it "raises ArgumentError if api_item is blank" do
      expect { described_class.new(api_item: {}) }.to raise_error(ArgumentError, "api_item cannot be blank")
    end

    it "raises ArgumentError if api_item is not Hash" do
      expect { described_class.new(api_item: nil) }.to raise_error(ArgumentError, "api_item must be a Hash")
    end

    it "handles cancelled orders" do
      cancelled_order = api_order.deep_dup
      cancelled_order["cancelledAt"] = "2023-01-03T12:00:00Z"
      cancelled_order["cancelReason"] = "CUSTOMER"
      cancelled_order["displayFinancialStatus"] = "REFUNDED"
      cancelled_order["displayFulfillmentStatus"] = "UNFULFILLED"

      parser = described_class.new(api_item: cancelled_order)
      result = parser.parse

      expect(result[:sale][:cancelled_at]).to eq(DateTime.parse("2023-01-03T12:00:00Z"))
      expect(result[:sale][:cancel_reason]).to eq("CUSTOMER")
      expect(result[:sale][:status]).to eq("cancelled")
    end

    it "handles completed orders" do
      completed_order = api_order.deep_dup
      completed_order["displayFinancialStatus"] = "PAID"
      completed_order["displayFulfillmentStatus"] = "FULFILLED"

      parser = described_class.new(api_item: completed_order)
      result = parser.parse

      expect(result[:sale][:status]).to eq("completed")
    end

    it "handles partially paid orders" do
      partially_paid_order = api_order.deep_dup
      partially_paid_order["displayFinancialStatus"] = "PARTIALLY_PAID"

      parser = described_class.new(api_item: partially_paid_order)
      result = parser.parse

      expect(result[:sale][:status]).to eq("partially-paid")
    end

    it "handles processing orders" do
      processing_order = api_order.deep_dup
      processing_order["displayFinancialStatus"] = "PENDING"

      parser = described_class.new(api_item: processing_order)
      result = parser.parse

      expect(result[:sale][:status]).to eq("processing")
    end

    it "downcases customer email" do
      uppercase_email_order = api_order.deep_dup
      uppercase_email_order["email"] = "CUSTOMER@EXAMPLE.COM"

      parser = described_class.new(api_item: uppercase_email_order)
      result = parser.parse

      expect(result[:customer][:email]).to eq("customer@example.com")
    end

    it "handles missing shipping address" do
      order_without_address = api_order.deep_dup
      order_without_address["shippingAddress"] = nil

      parser = described_class.new(api_item: order_without_address)
      result = parser.parse

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

      parser = described_class.new(api_item: order_without_variant)
      result = parser.parse

      expect(result[:sale_items].first).to include(
        shopify_edition_id: nil,
        shopify_product_id: nil
      )
    end

    it "handles missing product data" do
      order_without_product = api_order.deep_dup
      order_without_product["lineItems"]["nodes"].first["product"] = nil

      parser = described_class.new(api_item: order_without_product)
      result = parser.parse

      expect(result[:sale_items].first[:product]).to be_nil
    end

    it "parses product data correctly" do
      product_parser = instance_double(Shopify::ProductParser)
      allow(Shopify::ProductParser).to receive(:new).and_return(product_parser)
      allow(product_parser).to receive(:parse).and_return({
        shopify_id: "gid://shopify/Product/333",
        title: "Eve",
        franchise: "Stellar Blade",
        editions: [{
          shopify_id: "gid://shopify/ProductVariant/222",
          title: "Regular"
        }]
      })

      result = parser.parse

      expect(result[:sale_items].first[:product]).to include(
        shopify_id: "gid://shopify/Product/333",
        title: "Eve",
        franchise: "Stellar Blade"
      )
    end

    it "handles missing customer data" do
      order_without_customer = api_order.deep_dup
      order_without_customer["customer"] = nil
      order_without_customer["email"] = "customer@example.com"

      parser = described_class.new(api_item: order_without_customer)
      result = parser.parse

      expect(result[:customer]).to include(
        shopify_id: nil,
        email: "customer@example.com",
        first_name: nil,
        last_name: nil,
        phone: nil
      )
    end

    it "handles missing line items" do
      order_without_items = api_order.deep_dup
      order_without_items["lineItems"] = {"nodes" => []}

      parser = described_class.new(api_item: order_without_items)
      result = parser.parse

      expect(result[:sale_items]).to be_empty
    end

    it "handles missing dates" do
      order_without_dates = api_order.deep_dup
      order_without_dates["createdAt"] = nil
      order_without_dates["updatedAt"] = nil

      parser = described_class.new(api_item: order_without_dates)
      result = parser.parse

      expect(result[:sale][:shopify_created_at]).to be_nil
      expect(result[:sale][:shopify_updated_at]).to be_nil
    end
  end
end
