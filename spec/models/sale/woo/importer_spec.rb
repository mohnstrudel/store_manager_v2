# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Woo::Importer do
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

  describe ".import" do
    let(:parsed_sale) { sample_parsed_order[:sale] }
    let(:parsed_customer) { sample_parsed_order[:customer] }

    it "creates a new sale when none exists", :aggregate_failures do
      sale = described_class.import({sale: parsed_sale, customer: parsed_customer, products: []})

      expect(sale).to be_persisted
      expect(sale.woo_store_id.to_s).to eq(parsed_sale[:woo_id].to_s)
      expect(sale.total).to eq(BigDecimal(parsed_sale[:total]))
      expect(sale.customer.woo_store_id).to eq(parsed_customer[:woo_id].to_s)
    end

    it "updates the existing sale", :aggregate_failures do
      existing_sale = create(:sale, woo_store_id: parsed_sale[:woo_id], total: 100)

      described_class.import({sale: parsed_sale.merge(total: 200), customer: parsed_customer, products: []})

      expect(existing_sale.reload.total).to eq(200)
      expect(Sale.count).to eq(1)
    end

    it "resolves the order's import failure when the import succeeds" do
      store_order_id = parsed_sale[:woo_id].to_s
      Sale::ImportFailure.record(store_name: "woo", store_order_id:, message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

      described_class.import({sale: parsed_sale, customer: parsed_customer, products: []})

      expect(Sale::ImportFailure.find_by!(store_name: "woo", store_order_id:).resolved_at).to be_present
    end

    it "updates address snapshots for an existing sale", :aggregate_failures do
      existing_sale = create(:sale, woo_store_id: parsed_sale[:woo_id])

      described_class.import({
        sale: parsed_sale,
        customer: parsed_customer,
        addresses: {
          shipping: {address_1: "Updated Shipping St", city: "Berlin"},
          billing: {address_1: "Updated Billing St", city: "Munich"}
        },
        products: []
      })

      existing_sale.reload
      expect(existing_sale.shipping_address).to have_attributes(address_1: "Updated Shipping St", city: "Berlin")
      expect(existing_sale.billing_address).to have_attributes(address_1: "Updated Billing St", city: "Munich")
    end
  end

  describe ".import with parsed Woo orders" do
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
        parsed_woo_orders.each { |order| described_class.import(order) }
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
      let(:parsed_orders) { woo_orders.map { |order| Sale::Woo::Parser.parse(order) } }

      before do
        parsed_orders.pluck(:products).flatten.each do |p|
          create(:product, woo_store_id: p[:product_woo_id])
        end
      end

      it "persists shipping and billing address snapshots" do
        parsed_orders.each { |order| described_class.import(order) }

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
        parsed_orders.each { |order| described_class.import(order) }

        updated_order = Sale::Woo::Parser.parse(sample_order).tap do |order|
          order[:addresses][:shipping][:address_1] = "Updated Shipping St"
          order[:addresses][:billing][:address_1] = "Updated Billing St"
        end

        described_class.import(updated_order)

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
        allow(Product::Woo::Importer).to receive(:fetch_and_import).with(product_woo_id)

        described_class.import(parsed_order_with_missing_product)

        expect(Product::Woo::Importer).to have_received(:fetch_and_import).with(product_woo_id)
      end

      it "links the sale item to the product Woo returns" do
        allow(Product::Woo::Importer).to receive(:fetch_and_import).with(product_woo_id) do
          create(:product, woo_store_id: product_woo_id)
        end

        described_class.import(parsed_order_with_missing_product)

        sale = Sale.find_by_woo_id(parsed_order_with_missing_product[:sale][:woo_id])
        expect(sale.sale_items.map(&:product)).to include(Product.find_by_woo_id(product_woo_id))
      end

      it "skips the line item when Woo returns no product" do
        allow(Product::Woo::Importer).to receive(:fetch_and_import).and_return(nil)

        expect { described_class.import(parsed_order_with_missing_product) }.not_to raise_error
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

        described_class.import(parsed_order)

        aggregate_failures do
          expect(sale_item.reload.variant_id).to eq(stored_variant.id)
          expect(sale.reload.status).to eq("completed")
        end
      end
    end

    context "when a Woo line has a variation id and no recognized options" do
      let(:product) { create(:product, woo_store_id: "woo-product") }
      let!(:other_variant) { create(:variant, :with_version, product:) }
      let!(:known_variant) { create(:variant, :with_version, product:, woo_store_id: "14079") }
      let(:parsed_order) do
        {
          sale: sample_parsed_order[:sale].merge(woo_id: "woo-order"),
          customer: sample_parsed_order[:customer],
          products: [{
            sale_item_woo_id: "woo-line",
            product_woo_id: "woo-product",
            price: "10.00",
            expected_revenue: "10.00",
            qty: 1,
            variant: {woo_id: "14079", product_woo_id: "woo-product", options: []}
          }]
        }
      end

      def stored_line(variant:)
        create(:sale_item, product:, variant:, sale: create(:sale, woo_store_id: "woo-order"), woo_store_id: "woo-line")
      end

      it "assigns the known Variant to a new line and imports the order", :aggregate_failures do
        sale = described_class.import(parsed_order)

        expect(sale).to be_persisted
        expect(SaleItem.find_by_woo_id("woo-line").variant).to eq(known_variant)
      end

      it "fills a stored line with a blank Variant" do
        sale_item = stored_line(variant: other_variant)
        sale_item.update_column(:variant_id, nil) # rubocop:disable Rails/SkipsModelValidations

        described_class.import(parsed_order)

        expect(sale_item.reload.variant).to eq(known_variant)
      end

      it "keeps a stored Variant" do
        sale_item = stored_line(variant: other_variant)

        described_class.import(parsed_order)

        expect(sale_item.reload.variant).to eq(other_variant)
      end

      it "keeps a Variant set by manual repair" do
        sale_item = stored_line(variant: known_variant)
        sale_item.update_column(:variant_id, nil) # rubocop:disable Rails/SkipsModelValidations
        Variant::AssignmentRepair.repair_sale_item(sale_item_id: sale_item.id, variant_id: other_variant.id)

        described_class.import(parsed_order)

        expect(sale_item.reload.variant).to eq(other_variant)
      end

      it "ignores a known variation of another Product", :aggregate_failures do
        known_variant.woo_info.update!(store_id: "elsewhere")
        create(:variant, :with_version, product: create(:product), woo_store_id: "14079")

        expect { described_class.import(parsed_order) }.to raise_error(described_class::Error, /Variant must be selected/)
      end

      it "keeps today's outcome for an unknown variation without building a Variant", :aggregate_failures do
        known_variant.woo_info.update!(store_id: "elsewhere")

        expect {
          expect { described_class.import(parsed_order) }.to raise_error(described_class::Error, /Variant must be selected/)
        }.not_to change(Variant, :count)
      end

      it "still assigns the Variant matching recognized options over the stored one" do
        sale_item = stored_line(variant: other_variant)
        parsed_order[:products].first[:variant][:options] = [{name: "version", value: known_variant.version.value}]

        described_class.import(parsed_order)

        expect(sale_item.reload.variant).to eq(known_variant)
      end
    end

    context "when a line is skipped because its product was not found" do
      let(:product) { create(:product, woo_store_id: "woo-product") }
      let(:found_line) do
        {sale_item_woo_id: "found-line", product_woo_id: "woo-product", price: "10.00", expected_revenue: "10.00", qty: 1}
      end
      let(:skipped_lines) do
        [
          {sale_item_woo_id: "skipped-1", product_woo_id: "gone-1", price: "10.00", expected_revenue: "10.00", qty: 1},
          {sale_item_woo_id: "skipped-2", product_woo_id: "gone-2", price: "10.00", expected_revenue: "10.00", qty: 1}
        ]
      end
      let(:parsed_order) do
        {
          sale: sample_parsed_order[:sale].merge(woo_id: "woo-order"),
          customer: sample_parsed_order[:customer],
          products: [*skipped_lines, found_line]
        }
      end
      let(:failure) { Sale::ImportFailure.find_by!(store_name: "woo", store_order_id: "woo-order") }

      before do
        create(:variant, :with_version, product:, woo_store_id: "found-variation")
        found_line[:variant] = {woo_id: "found-variation", product_woo_id: "woo-product", options: []}
        allow(Product::Woo::Importer).to receive(:fetch_and_import).and_return(nil)
      end

      it "saves the order and leaves an unresolved failure naming each skipped line", :aggregate_failures do
        sale = described_class.import(parsed_order)

        expect(sale.reload.sale_items.size).to eq(1)
        expect(failure).to have_attributes(
          message: "Woo line skipped-1 (Woo product gone-1): product not found; " \
            "Woo line skipped-2 (Woo product gone-2): product not found",
          sentry_event_id: nil,
          resolved_at: nil,
          sale:
        )
      end

      it "stays open while a line is still skipped", :aggregate_failures do
        2.times { described_class.import(parsed_order) }

        expect(failure.resolved_at).to be_nil
        expect(failure.failure_count).to eq(2)
      end

      it "resolves when the order imports with no skipped line" do
        described_class.import(parsed_order)

        described_class.import(parsed_order.merge(products: [found_line]))

        expect(failure.resolved_at).to be_present
      end

      it "writes no failure when another line rolls the order back" do
        invalid_line = found_line.except(:variant)

        expect {
          expect { described_class.import(parsed_order.merge(products: [*skipped_lines, invalid_line])) }.to raise_error(described_class::Error)
        }.not_to change(Sale::ImportFailure, :count)
      end
    end

    context "when Woo reports a partially paid order" do
      it "leaves the unknown split unset on the sale and on its items", :aggregate_failures do
        partially_paid_order[:line_items].each do |line_item|
          create(:product, woo_store_id: line_item[:product_id].to_s)
        end

        described_class.import(Sale::Woo::Parser.parse(partially_paid_order))

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

        described_class.import(Sale::Woo::Parser.parse(partially_paid_order_with_deposit))

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

        described_class.import(Sale::Woo::Parser.parse(excluded_order))

        sale = Sale.find_by_woo_id(excluded_order[:id])
        expect(sale.settlement_status).to eq("paid")
        expect(Sale.economically_excluded).to include(sale)
      end
    end

    context "when the sale holds a stored line without a Variant" do
      let(:product) { create(:product, woo_store_id: "woo-product") }
      let!(:known_variant) { create(:variant, :with_version, product:, woo_store_id: "woo-variation") }
      let!(:stored_line) do
        create(
          :sale_item,
          product:,
          variant: known_variant,
          sale: create(:sale, woo_store_id: "woo-order"),
          expected_revenue: BigDecimal(50),
          woo_store_id: "stored-line"
        )
      end
      let(:parsed_order) do
        {
          sale: sample_parsed_order[:sale].merge(
            woo_id: "woo-order",
            expected_revenue: "100.00",
            received_revenue: "100.00",
            outstanding_revenue: "0.00",
            refunded_revenue: "0.00"
          ),
          customer: sample_parsed_order[:customer],
          products: [{
            sale_item_woo_id: "woo-line",
            product_woo_id: "woo-product",
            price: "50.00",
            expected_revenue: "50.00",
            qty: 1,
            variant: {woo_id: "woo-variation", product_woo_id: "woo-product", options: []}
          }]
        }
      end

      before { stored_line.update_column(:variant_id, nil) } # rubocop:disable Rails/SkipsModelValidations

      it "imports the order and allocates the stored line's revenue without choosing a Variant" do
        described_class.import(parsed_order)

        expect(stored_line.reload).to have_attributes(received_revenue: BigDecimal(50), variant_id: nil)
      end
    end

    context "when a line fails validation" do
      let(:product) { create(:product, woo_store_id: "woo-product") }
      let!(:sale) { create(:sale, woo_store_id: "woo-order", status: "processing") }
      let(:parsed_order) do
        {
          sale: sample_parsed_order[:sale].merge(woo_id: "woo-order", status: "completed"),
          customer: sample_parsed_order[:customer],
          products: [{
            sale_item_woo_id: "woo-line",
            product_woo_id: "woo-product",
            price: "10.00",
            expected_revenue: "10.00",
            qty: 1
          }]
        }
      end

      before { create(:variant, :with_version, product:) }

      it "leaves the order's import failure unresolved when the import rolls back" do
        Sale::ImportFailure.record(store_name: "woo", store_order_id: "woo-order", message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

        expect { described_class.import(parsed_order) }.to raise_error(described_class::Error)

        expect(Sale::ImportFailure.find_by!(store_name: "woo", store_order_id: "woo-order").resolved_at).to be_nil
      end

      it "imports the order and keeps a stored line that has no Variant", :aggregate_failures do
        sale_item = create(:sale_item, product:, sale:, variant: product.variants.real.first, woo_store_id: "woo-line", price: 1)
        sale_item.update_column(:variant_id, nil) # rubocop:disable Rails/SkipsModelValidations

        described_class.import(parsed_order)

        expect(sale.reload.status).to eq("completed")
        expect(sale_item.reload).to have_attributes(variant_id: nil, price: BigDecimal(10))
      end

      it "names the line, product, and persisted record, and rolls the order back", :aggregate_failures do
        foreign_variant = create(:variant, :with_version, product: create(:product))
        sale_item = create(:sale_item, product:, sale:, variant: product.variants.real.first, woo_store_id: "woo-line")
        sale_item.update_column(:variant_id, foreign_variant.id) # rubocop:disable Rails/SkipsModelValidations

        expect { described_class.import(parsed_order) }.to raise_error(
          described_class::Error,
          "Woo line woo-line (Woo product woo-product): SaleItem ##{sale_item.id}: " \
          "Validation failed: Variant must belong to the selected Product"
        )

        expect(sale.reload.status).to eq("processing")
      end

      it "names only the class of a record that was never saved", :aggregate_failures do
        expect { described_class.import(parsed_order) }.to raise_error(
          described_class::Error,
          "Woo line woo-line (Woo product woo-product): SaleItem: " \
          "Validation failed: Variant must be selected"
        )

        expect(sale.reload.status).to eq("processing")
      end
    end
  end
end
