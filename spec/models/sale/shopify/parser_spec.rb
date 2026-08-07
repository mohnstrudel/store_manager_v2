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
        "firstName" => "John",
        "lastName" => "Doe",
        "address1" => "123 Main St",
        "address2" => "Apt 4B",
        "city" => "New York",
        "company" => "Acme Inc",
        "country" => "United States",
        "provinceCode" => "NY",
        "zip" => "10001",
        "phone" => "555-9999"
      },
      "billingAddress" => {
        "firstName" => "Jane",
        "lastName" => "Doe",
        "address1" => "500 Billing Ave",
        "address2" => "Suite 2",
        "city" => "Boston",
        "company" => "Billing Inc",
        "country" => "United States",
        "province" => "Massachusetts",
        "zip" => "02110",
        "phone" => "555-0000"
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
        variants: []
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

      it "handles missing addresses" do
        order_without_address = api_order.deep_dup
        order_without_address["shippingAddress"] = nil
        order_without_address["billingAddress"] = nil

        result = described_class.parse(order_without_address)

        expect(result[:addresses]).to eq(shipping: {}, billing: {email: "customer@example.com"})
      end

      it "keeps sale attributes free of address fields" do
        order_without_shipping_address = api_order.deep_dup
        order_without_shipping_address["shippingAddress"] = nil

        result = described_class.parse(order_without_shipping_address)

        expect(result[:sale]).not_to include(:address_1, :address_2, :city, :company, :country, :postcode, :state)
      end

      it "parses shipping and billing addresses separately" do
        result = described_class.parse(api_order)

        expect(result[:addresses]).to eq(
          shipping: {
            first_name: "John",
            last_name: "Doe",
            phone: "555-9999",
            company: "Acme Inc",
            address_1: "123 Main St",
            address_2: "Apt 4B",
            city: "New York",
            state: "NY",
            postcode: "10001",
            country: "United States"
          },
          billing: {
            first_name: "Jane",
            last_name: "Doe",
            email: "customer@example.com",
            phone: "555-0000",
            company: "Billing Inc",
            address_1: "500 Billing Ave",
            address_2: "Suite 2",
            city: "Boston",
            state: "Massachusetts",
            postcode: "02110",
            country: "United States"
          }
        )
      end

      it "handles missing variant data" do
        order_without_variant = api_order.deep_dup
        order_without_variant["lineItems"]["nodes"].first["variant"] = nil

        result = described_class.parse(order_without_variant)

        expect(result[:sale_items].first).to include(
          variant_store_id: nil,
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
            variants: [{
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
            variants: []
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

  describe "payment fields" do
    let(:partially_paid_order) do
      api_order.deep_dup.merge(
        "displayFinancialStatus" => "PARTIALLY_PAID",
        "currentTotalPriceSet" => {"shopMoney" => {"amount" => "95.00"}},
        "totalReceivedSet" => {"shopMoney" => {"amount" => "50.00"}},
        "totalOutstandingSet" => {"shopMoney" => {"amount" => "45.00"}},
        "netPaymentSet" => {"shopMoney" => {"amount" => "50.00"}},
        "totalRefundedSet" => {"shopMoney" => {"amount" => "0.00"}},
        "paymentGatewayNames" => ["shopify_payments"]
      )
    end

    it "parses order-level payment amounts for partially paid orders" do
      result = described_class.parse(partially_paid_order)

      expect(result[:sale]).to include(
        expected_revenue: "95.00",
        received_revenue: "50.00",
        outstanding_revenue: "45.00",
        net_payment: "50.00",
        refunded_revenue: "0.00",
        payment_gateway_names: ["shopify_payments"]
      )
    end

    it "falls back to totalPriceSet when currentTotalPriceSet is missing" do
      result = described_class.parse(api_order)

      expect(result[:sale][:expected_revenue]).to eq("100.00")
    end

    it "defaults payment fields when the payload has none" do
      result = described_class.parse(api_order)

      expect(result[:sale]).to include(
        received_revenue: nil,
        outstanding_revenue: nil,
        refunded_revenue: nil,
        net_payment: nil,
        payment_gateway_names: [],
        payment_terms_name: nil,
        payment_terms_type: nil,
        payment_due: nil,
        payment_overdue: false
      )
    end

    it "parses refunded amounts for refunded orders" do
      refunded_order = api_order.deep_dup.merge(
        "displayFinancialStatus" => "REFUNDED",
        "totalRefundedSet" => {"shopMoney" => {"amount" => "95.00"}},
        "netPaymentSet" => {"shopMoney" => {"amount" => "0.00"}}
      )

      result = described_class.parse(refunded_order)

      expect(result[:sale]).to include(refunded_revenue: "95.00", net_payment: "0.00")
    end

    it "parses payment terms and the earliest unpaid schedule due date" do
      order_with_terms = api_order.deep_dup.merge(
        "paymentTerms" => {
          "paymentTermsName" => "Within 30 days",
          "paymentTermsType" => "NET",
          "overdue" => true,
          "paymentSchedules" => {
            "nodes" => [
              {"dueAt" => "2023-01-10T12:00:00Z", "completedAt" => "2023-01-09T12:00:00Z"},
              {"dueAt" => "2023-03-01T12:00:00Z", "completedAt" => nil},
              {"dueAt" => "2023-02-01T12:00:00Z", "completedAt" => nil}
            ]
          }
        }
      )

      result = described_class.parse(order_with_terms)

      expect(result[:sale]).to include(
        payment_terms_name: "Within 30 days",
        payment_terms_type: "NET",
        payment_overdue: true,
        payment_due: DateTime.parse("2023-02-01T12:00:00Z")
      )
    end

    it "parses an exact native Shopify payment-plan snapshot" do
      order_with_terms = api_order.deep_dup.merge(
        "paymentTerms" => {
          "id" => "gid://shopify/PaymentTerms/77",
          "paymentTermsName" => "Four payments",
          "paymentTermsType" => "FIXED",
          "overdue" => false,
          "paymentSchedules" => {
            "nodes" => [
              {
                "id" => "gid://shopify/PaymentSchedule/1",
                "balanceDue" => {"amount" => "0.00", "currencyCode" => "EUR"},
                "totalBalance" => {"amount" => "250.00", "currencyCode" => "EUR"},
                "completedAt" => "2023-01-09T12:00:00Z",
                "dueAt" => "2023-01-10T12:00:00Z"
              },
              {
                "id" => "gid://shopify/PaymentSchedule/2",
                "balanceDue" => {"amount" => "250.00", "currencyCode" => "EUR"},
                "totalBalance" => {"amount" => "250.00", "currencyCode" => "EUR"},
                "completedAt" => nil,
                "dueAt" => "2023-02-10T12:00:00Z"
              }
            ]
          }
        }
      )

      result = described_class.parse(order_with_terms)

      expect(result[:payment_plan]).to eq(
        attributes: {
          provider: "shopify",
          external_id: "gid://shopify/PaymentTerms/77",
          external_origin_order_id: "gid://shopify/Order/12345",
          kind: "payment_terms",
          status: "active",
          expected_parts: 2,
          currency: "EUR",
          projected_total: BigDecimal("500.00"),
          deposit_percent: nil,
          next_due_at: DateTime.parse("2023-02-10T12:00:00Z")
        },
        parts: [
          {
            provider_part_id: "gid://shopify/PaymentSchedule/1",
            sequence: 1,
            external_order_id: "gid://shopify/Order/12345",
            amount: "250.00",
            currency: "EUR",
            due_at: DateTime.parse("2023-01-10T12:00:00Z"),
            provider_completed_at: DateTime.parse("2023-01-09T12:00:00Z")
          },
          {
            provider_part_id: "gid://shopify/PaymentSchedule/2",
            sequence: 2,
            external_order_id: "gid://shopify/Order/12345",
            amount: "250.00",
            currency: "EUR",
            due_at: DateTime.parse("2023-02-10T12:00:00Z"),
            provider_completed_at: nil
          }
        ]
      )
    end

    it "records a contract total but no deposit share when schedule amounts are equal" do
      order_with_equal_terms = api_order.deep_dup.merge(
        "paymentTerms" => {
          "id" => "gid://shopify/PaymentTerms/79",
          "paymentTermsName" => "Four payments",
          "paymentTermsType" => "FIXED",
          "overdue" => false,
          "paymentSchedules" => {
            "nodes" => [
              {"id" => "s1", "totalBalance" => {"amount" => "255.00", "currencyCode" => "EUR"}, "completedAt" => nil, "dueAt" => "2023-01-10T12:00:00Z"},
              {"id" => "s2", "totalBalance" => {"amount" => "255.00", "currencyCode" => "EUR"}, "completedAt" => nil, "dueAt" => "2023-02-10T12:00:00Z"},
              {"id" => "s3", "totalBalance" => {"amount" => "255.00", "currencyCode" => "EUR"}, "completedAt" => nil, "dueAt" => "2023-03-10T12:00:00Z"},
              {"id" => "s4", "totalBalance" => {"amount" => "255.00", "currencyCode" => "EUR"}, "completedAt" => nil, "dueAt" => "2023-04-10T12:00:00Z"}
            ]
          }
        }
      )

      result = described_class.parse(order_with_equal_terms)

      expect(result[:payment_plan][:attributes]).to include(
        expected_parts: 4,
        projected_total: BigDecimal("1020.00"),
        deposit_percent: nil
      )
    end

    it "records both a contract total and a deposit share when the schedule amounts differ" do
      order_with_deposit_terms = api_order.deep_dup.merge(
        "paymentTerms" => {
          "id" => "gid://shopify/PaymentTerms/80",
          "paymentTermsName" => "Deposit then instalments",
          "paymentTermsType" => "FIXED",
          "overdue" => false,
          "paymentSchedules" => {
            "nodes" => [
              {"id" => "s1", "totalBalance" => {"amount" => "306.00", "currencyCode" => "EUR"}, "completedAt" => nil, "dueAt" => "2023-01-10T12:00:00Z"},
              {"id" => "s2", "totalBalance" => {"amount" => "238.00", "currencyCode" => "EUR"}, "completedAt" => nil, "dueAt" => "2023-02-10T12:00:00Z"},
              {"id" => "s3", "totalBalance" => {"amount" => "238.00", "currencyCode" => "EUR"}, "completedAt" => nil, "dueAt" => "2023-03-10T12:00:00Z"},
              {"id" => "s4", "totalBalance" => {"amount" => "238.00", "currencyCode" => "EUR"}, "completedAt" => nil, "dueAt" => "2023-04-10T12:00:00Z"}
            ]
          }
        }
      )

      result = described_class.parse(order_with_deposit_terms)

      expect(result[:payment_plan][:attributes]).to include(
        expected_parts: 4,
        projected_total: BigDecimal("1020.00"),
        deposit_percent: BigDecimal("30.00")
      )
    end

    it "records a contract total but no deposit share for a single-schedule plan" do
      order_with_single_schedule = api_order.deep_dup.merge(
        "paymentTerms" => {
          "id" => "gid://shopify/PaymentTerms/81",
          "paymentTermsName" => "Net 30",
          "paymentTermsType" => "NET",
          "overdue" => false,
          "paymentSchedules" => {
            "nodes" => [
              {"id" => "s1", "totalBalance" => {"amount" => "1020.00", "currencyCode" => "EUR"}, "completedAt" => nil, "dueAt" => "2023-01-10T12:00:00Z"}
            ]
          }
        }
      )

      result = described_class.parse(order_with_single_schedule)

      expect(result[:payment_plan][:attributes]).to include(
        expected_parts: 1,
        projected_total: BigDecimal("1020.00"),
        deposit_percent: nil
      )
    end

    it "leaves payment_due empty when all schedules are completed" do
      order_with_completed_terms = api_order.deep_dup.merge(
        "paymentTerms" => {
          "paymentTermsName" => "Fixed",
          "paymentTermsType" => "FIXED",
          "overdue" => false,
          "paymentSchedules" => {
            "nodes" => [
              {"dueAt" => "2023-01-10T12:00:00Z", "completedAt" => "2023-01-09T12:00:00Z"}
            ]
          }
        }
      )

      result = described_class.parse(order_with_completed_terms)

      expect(result[:sale][:payment_due]).to be_nil
    end

    it "parses line item expected revenue from discountedTotalSet" do
      discounted_order = api_order.deep_dup
      discounted_order["lineItems"]["nodes"].first["discountedTotalSet"] = {"shopMoney" => {"amount" => "85.00"}}

      result = described_class.parse(discounted_order)

      expect(result[:sale_items].first[:expected_revenue]).to eq("85.00")
    end

    it "falls back to originalTotalSet for line item expected revenue" do
      result = described_class.parse(api_order)

      expect(result[:sale_items].first[:expected_revenue]).to eq("95.00")
    end

    it "parses expected revenue for every line item of a multi-product order" do
      multi_line_order = api_order.deep_dup
      second_line = multi_line_order["lineItems"]["nodes"].first.deep_dup
      second_line["id"] = "gid://shopify/LineItem/222"
      second_line["discountedTotalSet"] = {"shopMoney" => {"amount" => "40.00"}}
      multi_line_order["lineItems"]["nodes"] << second_line

      result = described_class.parse(multi_line_order)

      expect(result[:sale_items].map { |item| item[:expected_revenue] }).to eq(["95.00", "40.00"])
    end
  end

end
