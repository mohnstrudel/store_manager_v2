# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::PullSalesJob do
  let(:job) { described_class.new }
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
        parsed = job.parse_all(woo_orders)
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

  describe "#get_customer_id" do
    context "when we receive a valid woo_id" do
      it "returns existing customer" do
        parsed_customer = parsed_woo_orders.first[:customer]
        existing_customer = create(
          :customer,
          email: "#{SecureRandom.hex(5)}@mail.com",
          woo_store_id: parsed_customer[:woo_id]
        )
        parsed_customer_id = job.get_customer_id(parsed_customer)

        expect(parsed_customer_id).to eq(existing_customer.id)
      end

      it "creates a customer with only Woo store information" do
        parsed_customer_id = job.get_customer_id({
          email: nil,
          first_name: nil,
          last_name: nil,
          phone: nil,
          woo_id: "12345"
        })

        customer = Customer.find(parsed_customer_id)

        expect(customer.woo_info.store_id).to eq("12345")
      end
    end

    context "when we receive invalid woo_id" do
      let(:parsed_customer) { parsed_woo_orders.last[:customer] }

      let(:existing_customer) {
        create(
          :customer,
          email: parsed_customer[:email],
          woo_store_id: nil
        )
      }

      it "returns existing customer if woo_id == 0" do
        existing_customer_id = existing_customer.id
        parsed_customer_id = job.get_customer_id(
          parsed_customer.merge(woo_id: 0)
        )

        expect(parsed_customer_id).to eq(existing_customer_id)
      end

      it "returns existing customer if woo_id == '0'" do
        existing_customer_id = existing_customer.id
        parsed_customer_id = job.get_customer_id(
          parsed_customer.merge(woo_id: "0")
        )

        expect(parsed_customer_id).to eq(existing_customer_id)
      end

      it "returns existing customer if woo_id == ''" do
        existing_customer_id = existing_customer.id
        parsed_customer_id = job.get_customer_id(
          parsed_customer.merge(woo_id: "")
        )

        expect(parsed_customer_id).to eq(existing_customer_id)
      end
    end
  end

  describe "#perform" do
    context "with id parameter" do
      it "fetches single order and creates sales" do
        allow(job).to receive(:api_get_order).with("123").and_return(sample_order)
        allow(job).to receive(:parse_all).and_return([sample_parsed_order])
        allow(job).to receive(:create_sales)

        job.perform(id: "123")

        expect(job).to have_received(:api_get_order).with("123")
        expect(job).to have_received(:parse_all).with([sample_order])
        expect(job).to have_received(:create_sales).with([sample_parsed_order])
      end
    end

    context "without id parameter" do
      it "fetches all orders and creates sales" do
        allow(job).to receive(:api_get_all_orders).with(2700, nil).and_return(woo_orders)
        allow(job).to receive(:parse_all).and_return(parsed_woo_orders)
        allow(job).to receive(:create_sales)

        job.perform

        expect(job).to have_received(:api_get_all_orders).with(2700, nil)
        expect(job).to have_received(:parse_all).with(woo_orders)
        expect(job).to have_received(:create_sales).with(parsed_woo_orders)
      end

      it "uses custom limit and pages when provided" do
        allow(job).to receive(:api_get_all_orders).with(100, 5).and_return(woo_orders)
        allow(job).to receive(:parse_all).and_return(parsed_woo_orders)
        allow(job).to receive(:create_sales)

        job.perform(limit: 100, pages: 5)

        expect(job).to have_received(:api_get_all_orders).with(100, 5)
      end

      it "keeps the full refresh path updating stored order statuses" do
        order = sample_order.deep_dup
        product = create(
          :product,
          woo_store_id: order[:line_items].first[:product_id].to_s
        )
        create(
          :variant,
          product:,
          woo_store_id: order[:line_items].first[:variation_id].to_s
        )
        existing_sale = create(
          :sale,
          woo_store_id: order[:id].to_s,
          status: "processing"
        )
        allow(job).to receive(:api_get_all_orders).with(1, nil).and_return([order])

        job.perform(limit: 1)

        expect(existing_sale.reload.status).to eq(order[:status])
      end
    end
  end

  describe "#parse" do
    it "parses order data correctly" do
      parsed = job.parse(sample_order)

      expect(parsed[:sale][:woo_id]).to eq(sample_order[:id])
      expect(parsed[:sale][:total]).to eq(BigDecimal("337.50"))
      expect(parsed[:customer][:woo_id]).to eq(sample_order[:customer_id])
      expect(parsed[:products]).to be_an(Array)
      expect(parsed[:products].first[:product_woo_id]).to eq(sample_order[:line_items].first[:product_id])
    end

    it "uses billing data for the customer when shipping is empty" do
      order_with_empty_shipping = sample_order.merge(shipping: {})
      parsed = job.parse(order_with_empty_shipping)

      expect(parsed[:customer][:email]).to eq(sample_order[:billing][:email])
    end

    it "keeps shipping and billing addresses separate" do
      changed_billing = sample_order.deep_dup
      changed_billing[:billing][:address_1] = "Billing-only street"

      parsed = job.parse(changed_billing)

      expect(parsed[:addresses][:shipping][:address_1]).to eq(sample_order[:shipping][:address_1])
      expect(parsed[:addresses][:billing][:address_1]).to eq("Billing-only street")
      expect(parsed[:sale]).not_to include(:address_1)
    end

    it "marks revenue as received when the order has been paid", :aggregate_failures do
      parsed = job.parse(sample_order)

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
      parsed = job.parse(unpaid_order)

      expect(parsed[:sale]).to include(
        settlement_status: "not_fully_paid",
        expected_revenue: BigDecimal("337.50"),
        received_revenue: BigDecimal("0.00"),
        outstanding_revenue: BigDecimal("337.50")
      )
      expect(parsed[:sale][:payment_gateway_names]).to eq([])
    end

    it "claims neither a full nor an empty payment when Woo reports a partial one", :aggregate_failures do
      parsed = job.parse(partially_paid_order)

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
      parsed = job.parse(partially_paid_order_with_deposit)

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

      parsed = job.parse(unpaid_deposit_order)

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

      parsed = job.parse(order_with_second_payment_flag)

      expect(parsed[:sale][:outstanding_revenue]).to be_nil
    end

    it "keeps refund conversion independent from received revenue", :aggregate_failures do
      refunded_order = sample_order.merge(refunds: [{total: "-50.00"}, {total: "-10.00"}])

      parsed = job.parse(refunded_order)

      expect(parsed[:sale][:refunded_revenue]).to eq(BigDecimal("67.50"))
      expect(parsed[:sale][:received_revenue]).to eq(BigDecimal("337.50"))
    end

    it "derives line item expected_revenue from the tax-inclusive line total" do
      parsed = job.parse(sample_order)

      expect(parsed[:products].first[:expected_revenue]).to eq(BigDecimal("264.38"))
    end
  end

  describe "settlement_status" do
    it "persists paid for a non-partial order with a payment date" do
      parsed = job.parse(sample_order)

      expect(parsed[:sale][:settlement_status]).to eq("paid")
    end

    it "persists not_fully_paid for a non-partial order without a payment date" do
      unpaid_order = sample_order.merge(date_paid: nil)

      parsed = job.parse(unpaid_order)

      expect(parsed[:sale][:settlement_status]).to eq("not_fully_paid")
    end

    it "persists not_fully_paid for a partially-paid order without plugin deposit evidence" do
      parsed = job.parse(partially_paid_order)

      expect(parsed[:sale][:settlement_status]).to eq("not_fully_paid")
    end

    it "persists not_fully_paid for a partially-paid order with a verified plugin deposit" do
      parsed = job.parse(partially_paid_order_with_deposit)

      expect(parsed[:sale][:settlement_status]).to eq("not_fully_paid")
    end

    it "keeps a real settlement mapping for cancelled, failed, and refunded orders instead of a placeholder", :aggregate_failures do
      %w[cancelled failed refunded].each do |status|
        order = sample_order.merge(status: status)

        expect(job.parse(order)[:sale][:settlement_status]).to eq("paid")
      end
    end

    it "raises for an unmapped Woo status instead of persisting a placeholder" do
      unmapped_order = sample_order.merge(status: "checkout-draft-unknown")

      expect { job.parse(unmapped_order) }.to raise_error(
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
        parsed = job.parse(order)

        expect(parsed[:sale][:total]).to eq(BigDecimal("90.00"))
        expect(parsed[:sale][:refunded_revenue]).to eq(BigDecimal("11.25"))
      end
    end

    it "reads the order's own currency field instead of a hardcoded literal" do
      allow(ExchangeRate).to receive(:usd_amount).and_call_original

      job.parse(sample_order)

      expect(ExchangeRate).to have_received(:usd_amount).with(anything, hash_including(currency: sample_order[:currency])).at_least(:once)
    end

    it "uses the order date for the historical rate lookup rather than a single global rate" do
      create(:exchange_rate, date: Date.new(2024, 1, 1), currency: "USD", rate: BigDecimal("1.5000"))
      order = sample_order.deep_dup.merge(date_created: "2024-06-01T00:00:00", total: "80.00")

      parsed = job.parse(order)

      expect(parsed[:sale][:total]).to eq(BigDecimal("120.00"))
    end

    it "converts the same payload to the same USD values on repeated synchronization" do
      first = job.parse(sample_order)
      second = job.parse(sample_order)

      expect(first[:sale][:total]).to eq(second[:sale][:total])
    end
  end

  describe "#parse_variant" do
    let(:line_item) { sample_order[:line_items].first }

    it "parses variant when found in meta_data" do
      variant = job.parse_variant(line_item)

      expect(variant).to be_present
      expect(variant[:options]).to be_present
    end

    it "returns nil when no variant found in meta_data" do
      line_item_without_variant = line_item.merge(meta_data: [])
      variant = job.parse_variant(line_item_without_variant)

      expect(variant).to be_nil
    end

    it "includes woo_id when variation_id is present" do
      line_item_with_variation_id = line_item.merge(variation_id: 123)
      variant = job.parse_variant(line_item_with_variation_id)

      expect(variant[:woo_id]).to eq(123)
    end
  end

  describe "#get_sale" do
    let(:parsed_sale) { sample_parsed_order[:sale] }

    it "creates new sale when not exists" do
      customer = create(:customer, id: parsed_sale[:customer_id] || 1)
      parsed_sale_with_customer = parsed_sale.merge(customer_id: customer.id)
      sale = job.get_sale(parsed_sale_with_customer)

      expect(sale).to be_persisted
      expect(sale.woo_store_id.to_s).to eq(parsed_sale[:woo_id].to_s)
      expect(sale.total).to eq(BigDecimal(parsed_sale[:total]))
    end

    it "updates existing sale" do
      existing_sale = create(:sale, woo_store_id: parsed_sale[:woo_id], total: 100)

      updated_sale = job.get_sale(parsed_sale.merge(total: 200))

      expect(updated_sale.id).to eq(existing_sale.id)
      expect(updated_sale.total).to eq(200)
    end

    it "updates address snapshots for an existing sale", :aggregate_failures do
      existing_sale = create(:sale, woo_store_id: parsed_sale[:woo_id])

      updated_sale = job.get_sale(
        parsed_sale,
        addresses: {
          shipping: {address_1: "Updated Shipping St", city: "Berlin"},
          billing: {address_1: "Updated Billing St", city: "Munich"}
        }
      )

      expect(updated_sale.id).to eq(existing_sale.id)
      expect(updated_sale.shipping_address).to have_attributes(address_1: "Updated Shipping St", city: "Berlin")
      expect(updated_sale.billing_address).to have_attributes(address_1: "Updated Billing St", city: "Munich")
    end
  end

  describe "#get_product_from_woo" do
    it "syncs product from Woo and returns it" do
      woo_id = "123"
      product = create(:product, woo_store_id: woo_id)

      sync_job = instance_double(Woo::PullProductsJob)
      allow(Woo::PullProductsJob).to receive(:new).and_return(sync_job)
      allow(sync_job).to receive(:get_and_create_product).with(woo_id)

      result = job.get_product_from_woo(woo_id)

      expect(sync_job).to have_received(:get_and_create_product).with(woo_id)
      expect(result).to eq(product)
    end

    it "returns nil when product not found" do
      woo_id = "999"

      sync_job = instance_double(Woo::PullProductsJob)
      allow(Woo::PullProductsJob).to receive(:new).and_return(sync_job)
      allow(sync_job).to receive(:get_and_create_product).with(woo_id)

      result = job.get_product_from_woo(woo_id)

      expect(result).to be_nil
    end
  end

  describe "#get_variant" do
    let(:parsed_variant) { sample_parsed_order[:products].first[:variant] }
    let(:product) { create(:product) }

    it "creates variant through Woo::PullVariantsJob" do
      sync_variants_job = instance_double(Woo::PullVariantsJob)
      allow(sync_variants_job).to receive(:create_variant)
      stub_const("Woo::PullSalesJob::SYNC_VARIANTS_JOB", sync_variants_job)

      job.get_variant(parsed_variant, product)

      expect(sync_variants_job).to have_received(:create_variant).with(
        product: product,
        variant_woo_id: parsed_variant[:woo_id],
        variant_types: {
          type: parsed_variant[:type],
          value: parsed_variant[:value]
        }
      )
    end

    it "returns nil when parsed_variant is blank" do
      result = job.get_variant(nil, product)
      expect(result).to be_nil
    end
  end

  describe "#create_sales" do
    let(:denpasar) { "Denpasar" }
    let(:weird_link) { "hey ho, let's go" }

    context "when we parsed orders from Woo API" do
      before do
        create(:sale, woo_store_id: parsed_woo_orders.first[:sale][:woo_id], total: 50)
        parsed_woo_orders.pluck(:products).flatten.each do |p|
          create(:product, woo_store_id: p[:product_woo_id])
        end
        first_product = Product.find_by_woo_id(
          parsed_woo_orders.first[:products].first[:product_woo_id]
        )
        create(
          :variant,
          product: first_product,
          woo_store_id: parsed_woo_orders.first[:products].first[:variant][:woo_id]
        ).tap do |e|
          e.woo_info.update(slug: weird_link)
        end
        job.create_sales(parsed_woo_orders)
      end

      it "saves each product to the DB" do
        expect(Sale.all.size).to eq(parsed_woo_orders.size)
      end

      it "assigns every product sale to a Variant" do
        with_variant = SaleItem.where.not(variant_id: nil)
        parsed_products_count = parsed_woo_orders.pluck(:products).flatten.size
        expect(with_variant.size).to eq(parsed_products_count)
      end

      it "reuses existing sales" do
        existing_sale = Sale.find_by_woo_id(parsed_woo_orders.first[:sale][:woo_id])
        expect(existing_sale.total).not_to eq(50)
      end

      it "updates the existing sale status from the pulled Woo payload" do
        existing_sale = Sale.find_by_woo_id(parsed_woo_orders.first[:sale][:woo_id])
        expect(existing_sale.status).to eq(parsed_woo_orders.first[:sale][:status])
      end

      it "persists the Woo order timestamp on the sale for analytics" do
        first_sale = Sale.find_by_woo_id(parsed_woo_orders.first[:sale][:woo_id])

        expect(first_sale.woo_created_at).to be_within(1.second).of(Time.zone.parse(parsed_woo_orders.first[:sale][:woo_created_at]))
      end

      it "reuses existing variants" do
        existing_variant = Variant.find_by_woo_id(parsed_woo_orders.first[:products].first[:variant][:woo_id])
        expect(existing_variant.woo_info.slug).to eq(weird_link)
      end

      it "allocates order-level revenue down to sale items", :aggregate_failures do
        first_sale = Sale.find_by_woo_id(parsed_woo_orders.first[:sale][:woo_id])
        item = first_sale.sale_items.first

        expect(item.expected_revenue).to eq(BigDecimal(parsed_woo_orders.first[:products].first[:expected_revenue]))
        expect(item.received_revenue).to eq(BigDecimal(parsed_woo_orders.first[:sale][:received_revenue]))
        expect(item.outstanding_revenue).to eq(BigDecimal(parsed_woo_orders.first[:sale][:outstanding_revenue]))
      end

      it "keeps allocated item revenue summing to the converted order-level totals", :aggregate_failures do
        first_sale = Sale.find_by_woo_id(parsed_woo_orders.first[:sale][:woo_id])

        expect(first_sale.sale_items.sum(&:received_revenue)).to eq(first_sale.received_revenue)
        expect(first_sale.sale_items.sum(&:outstanding_revenue)).to eq(first_sale.outstanding_revenue)
      end
    end

    context "when parsed orders include separate addresses" do
      before do
        job.parse_all(woo_orders).pluck(:products).flatten.each do |p|
          create(:product, woo_store_id: p[:product_woo_id])
        end
      end

      it "persists shipping and billing address snapshots" do
        job.create_sales(job.parse_all(woo_orders))

        sale = Sale.find_by_woo_id(sample_order[:id])
        expect(sale.shipping_address).to have_attributes(
          address_1: sample_order[:shipping][:address_1],
          city: sample_order[:shipping][:city]
        )
        expect(sale.billing_address).to have_attributes(
          address_1: sample_order[:billing][:address_1],
          email: sample_order[:billing][:email]
        )
      end

      it "updates existing address snapshots" do
        parsed_orders = job.parse_all(woo_orders)
        job.create_sales(parsed_orders)

        updated_orders = job.parse_all(woo_orders).tap do |orders|
          orders.first[:addresses][:shipping][:address_1] = "Updated Shipping St"
          orders.first[:addresses][:billing][:address_1] = "Updated Billing St"
        end

        job.create_sales(updated_orders)

        sale = Sale.find_by_woo_id(sample_order[:id])
        expect(sale.addresses.count).to eq(2)
        expect(sale.shipping_address).to have_attributes(address_1: "Updated Shipping St")
        expect(sale.billing_address).to have_attributes(address_1: "Updated Billing St")
      end
    end

    context "when product needs to be fetched from Woo" do
      let(:product_woo_id) { "999" }
      let(:parsed_order_with_missing_product) do
        parsed_woo_orders.first.tap do |order|
          order[:products].first[:product_woo_id] = product_woo_id
        end
      end

      it "fetches missing product from Woo" do
        Product.where_woo_ids([product_woo_id]).destroy_all

        sync_job = instance_double(Woo::PullProductsJob)
        allow(Woo::PullProductsJob).to receive(:new).and_return(sync_job)
        allow(sync_job).to receive(:get_and_create_product).with(product_woo_id)
        allow(job).to receive(:get_variant).and_return(nil)

        job.create_sales([parsed_order_with_missing_product])
        expect(Woo::PullProductsJob).to have_received(:new)
        expect(sync_job).to have_received(:get_and_create_product).with(product_woo_id)
      end

      it "skips product creation when product is blank" do
        allow(job).to receive_messages(
          get_product_from_woo: nil,
          get_variant: nil
        )

        expect { job.create_sales([parsed_order_with_missing_product]) }.not_to raise_error
      end
    end

    context "when an existing Woo line omits Variant metadata" do
      it "preserves the stored Variant while updating the Sale status" do
        product = create(:product, woo_store_id: "woo-product")
        stored_variant = create(
          :variant,
          :with_version,
          product:,
          woo_store_id: "woo-variant"
        )
        sale = create(:sale, woo_store_id: "woo-order", status: "processing")
        sale_item = create(
          :sale_item,
          product:,
          variant: stored_variant,
          sale:,
          woo_store_id: "woo-line"
        )
        parsed_order = {
          sale: {
            woo_id: "woo-order",
            status: "completed",
            total: "10.00",
            expected_revenue: "10.00",
            received_revenue: "10.00",
            outstanding_revenue: "0",
            refunded_revenue: "0"
          },
          customer: {
            email: "woo@example.com",
            first_name: "Woo",
            last_name: "Customer",
            phone: nil,
            woo_id: "woo-customer"
          },
          products: [{
            sale_item_woo_id: "woo-line",
            product_woo_id: "woo-product",
            price: "10.00",
            expected_revenue: "10.00",
            qty: 1
          }]
        }

        job.create_sales([parsed_order])

        aggregate_failures do
          expect(sale_item.reload.variant_id).to eq(stored_variant.id)
          expect(sale.reload.status).to eq("completed")
        end
      end
    end

    context "when Woo reports a partially paid order" do
      it "leaves the unknown split unset on the sale and on its items", :aggregate_failures do
        partially_paid_order[:line_items].each do |line_item|
          create(:product, woo_store_id: line_item[:product_id].to_s)
        end

        job.create_sales(job.parse_all([partially_paid_order]))

        sale = Sale.find_by_woo_id(partially_paid_order[:id])
        expect(sale).to have_attributes(
          settlement_status: "not_fully_paid",
          expected_revenue: BigDecimal("1115.54"),
          received_revenue: nil,
          outstanding_revenue: nil,
          refunded_revenue: BigDecimal(0)
        )
        expect(sale.sale_items.map(&:expected_revenue)).to contain_exactly(
          BigDecimal("700.41"), BigDecimal("415.13")
        )
        expect(sale.sale_items.map(&:received_revenue)).to all(be_nil)
        expect(sale.sale_items.map(&:outstanding_revenue)).to all(be_nil)
        expect(sale.sale_items.map(&:refunded_revenue)).to all(eq(BigDecimal(0)))
      end

      it "persists the converted plugin deposit as received revenue when a verified deposit exists", :aggregate_failures do
        partially_paid_order_with_deposit[:line_items].each do |line_item|
          create(:product, woo_store_id: line_item[:product_id].to_s)
        end

        job.create_sales(job.parse_all([partially_paid_order_with_deposit]))

        sale = Sale.find_by_woo_id(partially_paid_order_with_deposit[:id])
        expect(sale).to have_attributes(
          settlement_status: "not_fully_paid",
          received_revenue: BigDecimal("56.25"),
          outstanding_revenue: nil
        )
      end
    end

    context "when a Woo order is cancelled, failed, or refunded" do
      it "excludes it from positive economics while keeping a real settlement mapping" do
        excluded_order = sample_order.deep_dup.merge(status: "cancelled")
        excluded_order[:line_items].each { |line_item| create(:product, woo_store_id: line_item[:product_id].to_s) }

        job.create_sales(job.parse_all([excluded_order]))

        sale = Sale.find_by_woo_id(excluded_order[:id])
        expect(sale.settlement_status).to eq("paid")
        expect(Sale.economically_excluded).to include(sale)
      end
    end

    context "when an unexpected error happens while processing an order" do
      it "keeps the current order available for rescue logging" do
        allow(job).to receive(:get_customer_id).and_return(1)
        allow(job).to receive(:get_sale).and_raise(StandardError, "boom")
        allow(Rails.logger).to receive(:error)

        expect do
          job.create_sales([sample_parsed_order])
        end.to raise_error(StandardError, "boom")

        expect(Rails.logger).to have_received(:error).with(
          /Unexpected error for order #{sample_parsed_order[:sale][:woo_id]}: StandardError - boom/
        )
      end
    end
  end
end
