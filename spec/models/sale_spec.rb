# frozen_string_literal: true

# == Schema Information
#
# Table name: sales
#
#  id                    :bigint           not null, primary key
#  cancel_reason         :string
#  cancelled_at          :datetime
#  closed                :boolean          default(FALSE)
#  closed_at             :datetime
#  confirmed             :boolean          default(FALSE)
#  discount_total        :decimal(8, 2)
#  exchange_rate_date    :date
#  expected_revenue      :decimal(8, 2)
#  financial_status      :string
#  fulfillment_status    :string
#  net_payment           :decimal(8, 2)
#  note                  :string
#  outstanding_revenue   :decimal(8, 2)
#  payment_due           :datetime
#  payment_gateway_names :string           default([]), not null, is an Array
#  payment_overdue       :boolean          default(FALSE), not null
#  payment_terms_name    :string
#  payment_terms_type    :string
#  presentment_currency  :string
#  received_revenue      :decimal(8, 2)
#  refunded_revenue      :decimal(8, 2)
#  return_status         :string
#  settlement_status     :string
#  shipping_total        :decimal(8, 2)
#  shop_currency         :string
#  shopify_created_at    :datetime
#  shopify_name          :string
#  shopify_updated_at    :datetime
#  slug                  :string
#  status                :string
#  total                 :decimal(8, 2)
#  usd_conversion_rate   :decimal(18, 10)
#  woo_created_at        :datetime
#  woo_updated_at        :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  customer_id           :bigint           not null
#  shopify_id            :string
#  woo_id                :string
#
require "rails_helper"

RSpec.describe Sale do
  describe "#partially_paid?" do
    it "requires both received and outstanding money" do
      aggregate_failures do
        expect(build(:sale, received_revenue: 30, outstanding_revenue: 70)).to be_partially_paid
        expect(build(:sale, received_revenue: 0, outstanding_revenue: 100)).not_to be_partially_paid
        expect(build(:sale, received_revenue: 100, outstanding_revenue: 0)).not_to be_partially_paid
      end
    end
  end

  describe "addresses" do
    it "upserts shipping and billing address snapshots", :aggregate_failures do
      sale = create(:sale)

      sale.upsert_addresses!(
        shipping: {address_1: "Shipping St", city: "Berlin", country: "DE"},
        billing: {address_1: "Billing St", city: "Munich", country: "DE"}
      )

      expect(sale.shipping_address).to have_attributes(address_1: "Shipping St", city: "Berlin")
      expect(sale.billing_address).to have_attributes(address_1: "Billing St", city: "Munich")

      sale.upsert_addresses!(
        shipping: {address_1: "New Shipping St", city: "Hamburg", country: "DE"},
        billing: {address_1: "New Billing St", city: "Cologne", country: "DE"}
      )

      expect(sale.addresses.count).to eq(2)
      expect(sale.shipping_address.reload).to have_attributes(address_1: "New Shipping St", city: "Hamburg")
      expect(sale.billing_address.reload).to have_attributes(address_1: "New Billing St", city: "Cologne")
    end

    it "clears existing address snapshots when the incoming payload is blank" do
      sale = create(:sale)
      create(:sale_address, sale:, kind: :shipping)

      sale.upsert_addresses!(shipping: {}, billing: nil)

      expect(sale.reload.shipping_address).to be_nil
    end

    describe "#billing_differs_from_shipping?" do
      it "is false when either address is missing" do
        sale = create(:sale)
        create(:sale_address, sale:, kind: :shipping, address_1: "Same St")

        expect(sale.billing_differs_from_shipping?).to be false
      end

      it "is false when only billing contact fields differ" do
        sale = create(:sale)
        create(
          :sale_address,
          sale:,
          kind: :shipping,
          address_1: "Same St",
          city: "Berlin",
          country: "DE",
          email: "",
          phone: ""
        )
        create(
          :sale_address,
          sale:,
          kind: :billing,
          address_1: "Same St",
          city: "Berlin",
          country: "DE",
          email: "billing@example.com",
          phone: "+491234"
        )

        expect(sale.billing_differs_from_shipping?).to be false
      end

      it "is true when mailing address fields differ" do
        sale = create(:sale)
        create(:sale_address, sale:, kind: :shipping, address_1: "Shipping St", city: "Berlin", country: "DE")
        create(:sale_address, sale:, kind: :billing, address_1: "Billing St", city: "Berlin", country: "DE")

        expect(sale.billing_differs_from_shipping?).to be true
      end

      it "treats blank strings and nil values as equal" do
        sale = create(:sale)
        create(:sale_address, sale:, kind: :shipping, address_1: "Same St", address_2: "", city: "Berlin")
        create(:sale_address, sale:, kind: :billing, address_1: "Same St", address_2: nil, city: "Berlin")

        expect(sale.billing_differs_from_shipping?).to be false
      end
    end
  end

  describe "#follow_up_payment?" do
    it "is false for a sale with no payment plan at all" do
      sale = create(:sale)

      expect(sale.follow_up_payment?).to be false
    end

    it "is false for the plan's originating sale" do
      origin = create(:sale, shopify_store_id: "gid://shopify/Order/900")
      create_plan(
        external_origin_order_id: "900",
        parts: [{sequence: 1, provider_part_id: "part-1", external_order_id: "900"}]
      )

      expect(origin.follow_up_payment?).to be false
    end

    it "is true for a later part of the plan, not the origin" do
      origin = create(:sale, shopify_store_id: "gid://shopify/Order/900")
      follow_up = create(:sale, shopify_store_id: "gid://shopify/Order/901")
      create_plan(
        external_origin_order_id: "900",
        parts: [
          {sequence: 1, provider_part_id: "part-1", external_order_id: "900"},
          {sequence: 2, provider_part_id: "part-2", external_order_id: "901"}
        ]
      )

      expect(origin.follow_up_payment?).to be false
      expect(follow_up.follow_up_payment?).to be true
    end

    it "is false for every schedule of a Shopify payment_terms plan, whose schedules all belong to one order" do
      sale = create(:sale, shopify_store_id: "gid://shopify/Order/950")
      create_plan(
        provider: "shopify",
        kind: "payment_terms",
        external_origin_order_id: "950",
        parts: [
          {sequence: 1, provider_part_id: "sched-1", external_order_id: "950"},
          {sequence: 2, provider_part_id: "sched-2", external_order_id: "950"}
        ]
      )

      expect(sale.follow_up_payment?).to be false
    end
  end

  describe "#projected_item_price" do
    it "computes projected merchandise minus shipping for a single-item sale naming itself as plan origin" do
      sale = create(:sale, shopify_store_id: "gid://shopify/Order/100", shipping_total: BigDecimal("22.90"))
      create(:sale_item, sale:, expected_revenue: BigDecimal("87.29"))
      create_plan(external_id: "sub-origin", external_origin_order_id: "100", projected_total: BigDecimal("538.06"), parts: [])

      expect(sale.reload.projected_item_price).to eq(BigDecimal("515.16"))
    end

    it "is nil for every ineligible scenario", :aggregate_failures do
      no_plan = create(:sale, shipping_total: BigDecimal(20))
      create(:sale_item, sale: no_plan, expected_revenue: 300)
      expect(no_plan.projected_item_price).to be_nil

      multi_item = create(:sale, shopify_store_id: "gid://shopify/Order/101", shipping_total: BigDecimal(20))
      create(:sale_item, sale: multi_item, expected_revenue: 200)
      create(:sale_item, sale: multi_item, expected_revenue: 100)
      create_plan(external_id: "sub-multi-item", external_origin_order_id: "101", projected_total: 1000, parts: [])
      expect(multi_item.reload.projected_item_price).to be_nil

      multi_plan = create(:sale, shopify_store_id: "gid://shopify/Order/102", shipping_total: BigDecimal(20))
      create(:sale_item, sale: multi_plan, expected_revenue: 300)
      create_plan(external_id: "sub-plan-a", external_origin_order_id: "102", projected_total: 1000, parts: [])
      create_plan(external_id: "sub-plan-b", external_origin_order_id: "102", projected_total: 500, parts: [])
      expect(multi_plan.reload.projected_item_price).to be_nil

      create(:sale, shopify_store_id: "gid://shopify/Order/900")
      non_origin = create(:sale, shopify_store_id: "gid://shopify/Order/103", shipping_total: BigDecimal(20))
      create(:sale_item, sale: non_origin, expected_revenue: 300)
      create_plan(external_id: "sub-non-origin", external_origin_order_id: "900", projected_total: BigDecimal(1000), parts: [{provider_part_id: "sub-non-origin:1", sequence: 1, external_order_id: "103"}])
      expect(non_origin.reload.projected_item_price).to be_nil

      unknown_shipping = create(:sale, shopify_store_id: "gid://shopify/Order/104", shipping_total: nil)
      create(:sale_item, sale: unknown_shipping, expected_revenue: 300)
      create_plan(external_id: "sub-unknown-shipping", external_origin_order_id: "104", projected_total: 1000, parts: [])
      expect(unknown_shipping.reload.projected_item_price).to be_nil

      negative = create(:sale, shopify_store_id: "gid://shopify/Order/105", shipping_total: BigDecimal(50))
      create(:sale_item, sale: negative, expected_revenue: 300)
      create_plan(external_id: "sub-negative", external_origin_order_id: "105", projected_total: 40, parts: [])
      expect(negative.reload.projected_item_price).to be_nil
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe "search" do
    let!(:matching_customer) do
      create(
        :customer,
        email: "michele@example.com",
        first_name: "Michele",
        last_name: "Pomarico",
        phone: "+491729364665",
        woo_id: "cust-woo-123"
      )
    end
    let!(:matching_sale) do
      create(
        :sale,
        customer: matching_customer,
        shopify_name: "Order Alpha",
        note: "Fragile shipment",
        status: "processing",
        financial_status: "paid",
        fulfillment_status: "fulfilled",
        woo_id: "sale-woo-123",
        shopify_id: "gid://shopify/Order/123"
      )
    end
    let!(:matching_product) { create(:product, title: "Spirited Away") }
    let!(:other_sale) { create(:sale, shopify_name: "Order Beta", note: "Standard") }

    before do
      create(:sale_item, sale: matching_sale, product: matching_product)
    end

    it "finds sales by prefixes from their own and associated searchable fields" do
      aggregate_failures do
        expect(described_class.search_by("Order Al")).to include(matching_sale)
        expect(described_class.search_by("Frag")).to include(matching_sale)
        expect(described_class.search_by("proc")).to include(matching_sale)
        expect(described_class.search_by("mich")).to include(matching_sale)
        expect(described_class.search_by("Spiri")).to include(matching_sale)
      end
    end

    it "returns all sales when the query is blank" do
      expect(described_class.search_by("")).to contain_exactly(matching_sale, other_sale)
    end

    it "returns no sales when nothing matches" do
      expect(described_class.search_by("nonexistent")).to be_empty
    end
  end

  describe "Shopify currency fields" do
    it "persists complete currency data together" do
      sale = create(:sale,
        shop_currency: "EUR",
        presentment_currency: "CHF",
        usd_conversion_rate: BigDecimal("1.1250"),
        exchange_rate_date: Date.new(2026, 8, 21))

      expect(sale.reload).to have_attributes(
        shop_currency: "EUR",
        presentment_currency: "CHF",
        usd_conversion_rate: BigDecimal("1.1250"),
        exchange_rate_date: Date.new(2026, 8, 21)
      )
    end

    it "persists all four fields empty for a sale not yet synchronized" do
      sale = create(:sale)

      expect(sale.reload).to have_attributes(
        shop_currency: nil,
        presentment_currency: nil,
        usd_conversion_rate: nil,
        exchange_rate_date: nil
      )
    end

    it "rejects partially filled currency data" do
      expect {
        create(:sale, shop_currency: "EUR")
      }.to raise_error(ActiveRecord::StatementInvalid, /sales_currency_fields_all_or_none/)
    end

    it "rejects a shop currency code that is not three uppercase letters" do
      expect {
        create(:sale,
          shop_currency: "eur",
          presentment_currency: "CHF",
          usd_conversion_rate: BigDecimal("1.1250"),
          exchange_rate_date: Date.new(2026, 8, 21))
      }.to raise_error(ActiveRecord::StatementInvalid, /sales_shop_currency_format/)
    end

    it "rejects a presentment currency code that is not three uppercase letters" do
      expect {
        create(:sale,
          shop_currency: "EUR",
          presentment_currency: "chf",
          usd_conversion_rate: BigDecimal("1.1250"),
          exchange_rate_date: Date.new(2026, 8, 21))
      }.to raise_error(ActiveRecord::StatementInvalid, /sales_presentment_currency_format/)
    end

    it "rejects a non-positive conversion rate" do
      expect {
        create(:sale,
          shop_currency: "EUR",
          presentment_currency: "CHF",
          usd_conversion_rate: BigDecimal(0),
          exchange_rate_date: Date.new(2026, 8, 21))
      }.to raise_error(ActiveRecord::StatementInvalid, /sales_usd_conversion_rate_positive/)
    end
  end

  def create_plan(parts:, external_origin_order_id:, provider: "seal", kind: "installments", external_id: "subscription-1", projected_total: nil)
    SalePaymentPlan.reconcile!(
      attributes: {
        provider:,
        external_id:,
        external_origin_order_id:,
        kind:,
        status: "active",
        expected_parts: parts.empty? ? 1 : parts.size,
        projected_total:,
        synced_at: Time.current
      },
      parts:
    )
  end
end
