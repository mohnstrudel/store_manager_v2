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

  describe "#parse_all" do
    context "when we receive an array of orders from Woo API" do
      it "gives us parsed result" do
        parsed = job.parse_all(woo_orders)
        expect(parsed).to eq(parsed_woo_orders)
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
    end
  end

  describe "#parse" do
    it "parses order data correctly" do
      parsed = job.parse(sample_order)

      expect(parsed[:sale][:woo_id]).to eq(sample_order[:id])
      expect(parsed[:sale][:total]).to eq(sample_order[:total])
      expect(parsed[:customer][:woo_id]).to eq(sample_order[:customer_id])
      expect(parsed[:products]).to be_an(Array)
      expect(parsed[:products].first[:product_woo_id]).to eq(sample_order[:line_items].first[:product_id])
    end

    it "handles shipping address merging" do
      # When shipping is empty, it should use billing data
      order_with_empty_shipping = sample_order.merge(shipping: {})
      parsed = job.parse(order_with_empty_shipping)

      expect(parsed[:sale][:city]).to eq(sample_order[:billing][:city])
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
        create(
          :sale,
          woo_store_id: parsed_woo_orders.first[:sale][:woo_id],
          city: denpasar
        )
        create(
          :variant,
          woo_store_id: parsed_woo_orders.first[:products].first[:variant][:woo_id]
        ).tap do |e|
          e.woo_info.update(slug: weird_link)
        end
        parsed_woo_orders.pluck(:products).flatten.each do |p|
          create(:product, woo_store_id: p[:product_woo_id])
        end
        job.create_sales(parsed_woo_orders)
      end

      it "saves each product to the DB" do
        expect(Sale.all.size).to eq(parsed_woo_orders.size)
      end

      it "creates product sales with variants" do
        with_variant = SaleItem.where.not(variant_id: nil)
        parsed_variants_count = parsed_woo_orders.pluck(:products).flatten.count { |product| product[:variant].present? }
        expect(with_variant.size).to eq(parsed_variants_count)
      end

      it "reuses existing sales" do
        existing_sale = Sale.find_by_woo_id(parsed_woo_orders.first[:sale][:woo_id])
        expect(existing_sale.city).not_to eq(denpasar)
      end

      it "updates the existing sale status from the pulled Woo payload" do
        existing_sale = Sale.find_by_woo_id(parsed_woo_orders.first[:sale][:woo_id])
        expect(existing_sale.status).to eq(parsed_woo_orders.first[:sale][:status])
      end

      it "reuses existing variants" do
        existing_variant = Variant.find_by_woo_id(parsed_woo_orders.first[:products].first[:variant][:woo_id])
        expect(existing_variant.woo_info.slug).to eq(weird_link)
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
        # Ensure no product exists with this woo_id
        Product.where_woo_ids([product_woo_id]).destroy_all

        # Don't stub - let the actual method run, but mock the dependency
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
