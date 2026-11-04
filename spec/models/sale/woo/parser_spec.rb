# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Woo::Parser do
  let(:woo_orders) {
    JSON.parse(file_fixture("api_orders.json").read, symbolize_names: true)
  }
  let(:parsed_woo_orders) {
    JSON.parse(file_fixture("parsed_orders.json").read, symbolize_names: true)
  }
  let(:sample_order) { woo_orders.first }
  let(:sample_parsed_order) { parsed_woo_orders.first }
  let(:partially_paid_order) {
    JSON.parse(file_fixture("api_partially_paid_order.json").read, symbolize_names: true)
  }
  let(:partially_paid_order_with_deposit) {
    partially_paid_order.deep_dup.tap do |order|
      order[:meta_data] = [
        {id: 1, key: "_awcdp_deposits_deposit_amount", value: "50.00"},
        {id: 2, key: "_awcdp_deposits_deposit_paid", value: "yes"}
      ]
    end
  }
  let(:to_money) { ->(value) { value.nil? ? nil : BigDecimal(value.to_s) } }

  before do
    create(:exchange_rate, date: Date.new(2000, 1, 1), currency: "USD", rate: BigDecimal("1.1250"))
  end

  describe "#parse_all" do
    context "when we receive an array of orders from Woo API" do
      it "gives us parsed result" do
        parsed = described_class.parse_all(woo_orders)
        sale_money_fields = %i[discount_total shipping_total total expected_revenue received_revenue outstanding_revenue refunded_revenue]
        product_money_fields = %i[price expected_revenue]

        expected = parsed_woo_orders.map do |order|
          order.deep_dup.tap do |parsed_order|
            parsed_order[:sale].except!(:address_1, :address_2, :city, :company, :country, :postcode, :state)
            sale_money_fields.each { |field| parsed_order[:sale][field] = to_money.call(parsed_order[:sale][field]) }
            parsed_order[:products].each do |product|
              product_money_fields.each { |field| product[field] = to_money.call(product[field]) }
            end
          end
        end

        expect(parsed.map { |order| order.except(:addresses) }).to eq(expected)
        expect(parsed.first[:addresses]).to eq(
          shipping: {
            first_name: "Robert",
            last_name: "Dethloff",
            email: "",
            phone: "",
            company: "",
            address_1: "Schillerstrasse 68",
            address_2: "",
            city: "Bremerhaven",
            state: "",
            postcode: "27570",
            country: "DE"
          },
          billing: {
            first_name: "Robert",
            last_name: "Dethloff",
            email: "robert_dethloff@web.de",
            phone: "017631584891",
            company: "",
            address_1: "Schillerstrasse 68",
            address_2: "",
            city: "Bremerhaven",
            state: "",
            postcode: "27570",
            country: "DE"
          }
        )
      end
    end
  end

  describe "#parse" do
    it "parses order data correctly" do
      parsed = described_class.parse(sample_order)

      expect(parsed[:sale][:woo_id]).to eq(sample_order[:id])
      expect(parsed[:sale][:total]).to eq(BigDecimal("337.50"))
      expect(parsed[:customer][:woo_id]).to eq(sample_order[:customer_id])
      expect(parsed[:products]).to be_an(Array)
      expect(parsed[:products].first[:product_woo_id]).to eq(sample_order[:line_items].first[:product_id])
    end

    it "uses billing data for the customer when shipping is empty" do
      order_with_empty_shipping = sample_order.merge(shipping: {})
      parsed = described_class.parse(order_with_empty_shipping)

      expect(parsed[:customer][:email]).to eq(sample_order[:billing][:email])
    end

    it "keeps shipping and billing addresses separate" do
      changed_billing = sample_order.deep_dup
      changed_billing[:billing][:address_1] = "Billing-only street"

      parsed = described_class.parse(changed_billing)

      expect(parsed[:addresses][:shipping][:address_1]).to eq(sample_order[:shipping][:address_1])
      expect(parsed[:addresses][:billing][:address_1]).to eq("Billing-only street")
      expect(parsed[:sale]).not_to include(:address_1)
    end

    it "marks revenue as received when the order has been paid", :aggregate_failures do
      parsed = described_class.parse(sample_order)

      expect(parsed[:sale]).to include(
        woo_created_at: Time.zone.parse(sample_order[:date_created]),
        settlement_status: "paid",
        expected_revenue: BigDecimal("337.50"),
        received_revenue: BigDecimal("337.50"),
        outstanding_revenue: BigDecimal("0.00"),
        refunded_revenue: BigDecimal("0.00")
      )
      expect(parsed[:sale][:payment_gateway_names]).to eq([sample_order[:payment_method_title]])
    end

    it "marks revenue as outstanding when the order has not been paid", :aggregate_failures do
      unpaid_order = sample_order.merge(date_paid: nil, payment_method_title: nil)
      parsed = described_class.parse(unpaid_order)

      expect(parsed[:sale]).to include(
        settlement_status: "not_fully_paid",
        expected_revenue: BigDecimal("337.50"),
        received_revenue: BigDecimal("0.00"),
        outstanding_revenue: BigDecimal("337.50")
      )
      expect(parsed[:sale][:payment_gateway_names]).to eq([])
    end

    it "claims neither a full nor an empty payment when Woo reports a partial one", :aggregate_failures do
      parsed = described_class.parse(partially_paid_order)

      expect(parsed[:sale]).to include(
        status: "partially-paid",
        settlement_status: "not_fully_paid",
        expected_revenue: BigDecimal("1115.54"),
        received_revenue: nil,
        outstanding_revenue: nil,
        refunded_revenue: BigDecimal("0.00")
      )
    end

    it "persists the converted plugin deposit as received revenue when the deposit is verified paid", :aggregate_failures do
      parsed = described_class.parse(partially_paid_order_with_deposit)

      expect(parsed[:sale]).to include(
        settlement_status: "not_fully_paid",
        received_revenue: BigDecimal("56.25"),
        outstanding_revenue: nil
      )
    end

    it "never reads an unverified deposit as received revenue" do
      unpaid_deposit_order = partially_paid_order.deep_dup.tap do |order|
        order[:meta_data] = [
          {id: 1, key: "_awcdp_deposits_deposit_amount", value: "50.00"},
          {id: 2, key: "_awcdp_deposits_deposit_paid", value: "no"}
        ]
      end

      parsed = described_class.parse(unpaid_deposit_order)

      expect(parsed[:sale][:received_revenue]).to be_nil
    end

    it "never treats the plugin's post-deposit flag as known outstanding revenue" do
      order_with_second_payment_flag = partially_paid_order.deep_dup.tap do |order|
        order[:meta_data] = [
          {id: 1, key: "_awcdp_deposits_deposit_amount", value: "50.00"},
          {id: 2, key: "_awcdp_deposits_deposit_paid", value: "yes"},
          {id: 3, key: "_awcdp_deposits_second_payment_paid", value: "yes"}
        ]
      end

      parsed = described_class.parse(order_with_second_payment_flag)

      expect(parsed[:sale][:outstanding_revenue]).to be_nil
    end

    it "keeps refund conversion independent from received revenue", :aggregate_failures do
      refunded_order = sample_order.merge(refunds: [{total: "-50.00"}, {total: "-10.00"}])

      parsed = described_class.parse(refunded_order)

      expect(parsed[:sale][:refunded_revenue]).to eq(BigDecimal("67.50"))
      expect(parsed[:sale][:received_revenue]).to eq(BigDecimal("337.50"))
    end

    it "derives line item expected_revenue from the tax-inclusive line total" do
      parsed = described_class.parse(sample_order)

      expect(parsed[:products].first[:expected_revenue]).to eq(BigDecimal("264.38"))
    end
  end

  describe "settlement_status" do
    it "persists paid for a non-partial order with a payment date" do
      parsed = described_class.parse(sample_order)

      expect(parsed[:sale][:settlement_status]).to eq("paid")
    end

    it "persists not_fully_paid for a non-partial order without a payment date" do
      unpaid_order = sample_order.merge(date_paid: nil)

      parsed = described_class.parse(unpaid_order)

      expect(parsed[:sale][:settlement_status]).to eq("not_fully_paid")
    end

    it "persists not_fully_paid for a partially-paid order without plugin deposit evidence" do
      parsed = described_class.parse(partially_paid_order)

      expect(parsed[:sale][:settlement_status]).to eq("not_fully_paid")
    end

    it "persists not_fully_paid for a partially-paid order with a verified plugin deposit" do
      parsed = described_class.parse(partially_paid_order_with_deposit)

      expect(parsed[:sale][:settlement_status]).to eq("not_fully_paid")
    end

    it "keeps a real settlement mapping for cancelled, failed, and refunded orders instead of a placeholder", :aggregate_failures do
      %w[cancelled failed refunded].each do |status|
        order = sample_order.merge(status: status)

        expect(described_class.parse(order)[:sale][:settlement_status]).to eq("paid")
      end
    end

    it "persists not_fully_paid for an on-hold order without a payment date" do
      on_hold_order = sample_order.merge(status: "on-hold", date_paid: nil)

      expect(described_class.parse(on_hold_order)[:sale][:settlement_status]).to eq("not_fully_paid")
    end

    it "maps every status in Sale::STATUSES", :aggregate_failures do
      Sale::STATUSES.each do |status|
        expect { described_class.parse(sample_order.merge(status:, date_paid: nil)) }.not_to raise_error
      end
    end

    it "raises for an unmapped Woo status instead of persisting a placeholder" do
      unmapped_order = sample_order.merge(status: "checkout-draft-unknown")

      expect { described_class.parse(unmapped_order) }.to raise_error(
        ArgumentError, 'Unmapped Woo status: "checkout-draft-unknown"'
      )
    end
  end

  describe "USD conversion" do
    it "converts EUR order and refund totals to USD using woo_created_at, not pull time", :aggregate_failures do
      order = sample_order.deep_dup.merge(
        date_created: "2026-08-21T12:00:00",
        total: "80.00",
        refunds: [{total: "-10.00"}]
      )

      travel_to(Time.zone.parse("2030-01-01T00:00:00Z")) do
        parsed = described_class.parse(order)

        expect(parsed[:sale][:total]).to eq(BigDecimal("90.00"))
        expect(parsed[:sale][:refunded_revenue]).to eq(BigDecimal("11.25"))
      end
    end

    it "reads the order's own currency field instead of a hardcoded literal" do
      allow(ExchangeRate).to receive(:usd_amount).and_call_original

      described_class.parse(sample_order)

      expect(ExchangeRate).to have_received(:usd_amount).with(anything, hash_including(currency: sample_order[:currency])).at_least(:once)
    end

    it "uses the order date for the historical rate lookup rather than a single global rate" do
      create(:exchange_rate, date: Date.new(2024, 1, 1), currency: "USD", rate: BigDecimal("1.5000"))
      order = sample_order.deep_dup.merge(date_created: "2024-06-01T00:00:00", total: "80.00")

      parsed = described_class.parse(order)

      expect(parsed[:sale][:total]).to eq(BigDecimal("120.00"))
    end

    it "converts the same payload to the same USD values on repeated synchronization" do
      first = described_class.parse(sample_order)
      second = described_class.parse(sample_order)

      expect(first[:sale][:total]).to eq(second[:sale][:total])
    end
  end
end
