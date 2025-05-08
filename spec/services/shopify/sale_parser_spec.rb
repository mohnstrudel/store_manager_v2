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

    let(:parser) { described_class.new(api_order) }

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

      expect(result[:product_sales].first).to include(
        shopify_id: "gid://shopify/LineItem/111",
        price: "95.00",
        qty: 1,
        variation_title: "Regular",
        shopify_variation_id: "gid://shopify/ProductVariant/222",
        shopify_product_id: "gid://shopify/Product/333",
        full_title: "Stellar Blade - Eve | 1:4 Resin Statue"
      )
    end

    it "returns nil if order is blank" do
      parser = described_class.new(nil)
      expect(parser.parse).to be_nil
    end

    it "handles cancelled orders" do
      cancelled_order = api_order.deep_dup
      cancelled_order["cancelledAt"] = "2023-01-03T12:00:00Z"
      cancelled_order["cancelReason"] = "CUSTOMER"
      cancelled_order["displayFinancialStatus"] = "REFUNDED"
      cancelled_order["displayFulfillmentStatus"] = "UNFULFILLED"

      parser = described_class.new(cancelled_order)
      result = parser.parse

      expect(result[:sale][:cancelled_at]).to eq(DateTime.parse("2023-01-03T12:00:00Z"))
      expect(result[:sale][:cancel_reason]).to eq("CUSTOMER")
      expect(result[:sale][:status]).to eq("cancelled")
    end

    it "handles completed orders" do
      completed_order = api_order.deep_dup
      completed_order["displayFinancialStatus"] = "PAID"
      completed_order["displayFulfillmentStatus"] = "FULFILLED"

      parser = described_class.new(completed_order)
      result = parser.parse

      expect(result[:sale][:status]).to eq("completed")
    end

    it "handles partially paid orders" do
      partially_paid_order = api_order.deep_dup
      partially_paid_order["displayFinancialStatus"] = "PARTIALLY_PAID"

      parser = described_class.new(partially_paid_order)
      result = parser.parse

      expect(result[:sale][:status]).to eq("partially-paid")
    end

    it "handles processing orders" do
      processing_order = api_order.deep_dup
      processing_order["displayFinancialStatus"] = "PENDING"

      parser = described_class.new(processing_order)
      result = parser.parse

      expect(result[:sale][:status]).to eq("processing")
    end

    it "downcases customer email" do
      uppercase_email_order = api_order.deep_dup
      uppercase_email_order["email"] = "CUSTOMER@EXAMPLE.COM"

      parser = described_class.new(uppercase_email_order)
      result = parser.parse

      expect(result[:customer][:email]).to eq("customer@example.com")
    end
  end
end
