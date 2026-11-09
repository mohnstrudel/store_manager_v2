# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Shopify::Importer, :aggregate_failures do
  let(:parsed_orders) { instance_eval(file_fixture("shopify_parsed_orders.rb").read) }
  let(:valid_parsed_order) { parsed_orders.first }
  let(:importer) { described_class.new(valid_parsed_order) }
  let(:api_client) { instance_double(Shopify::Api::Client, fetch_product: nil) }

  def import_order(parsed_order = valid_parsed_order)
    described_class.import(parsed_order)
  end

  before do
    allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
    allow(Shopify::PullProductJob).to receive(:perform_later)
    allow(Product::Shopify::Importer).to receive(:import) do |parsed_product|
      product = Product.find_by_shopify_id(parsed_product[:store_id]) || Product.find_by(title: parsed_product[:title]) || Product.new
      product.assign_attributes(
        title: parsed_product[:title],
        franchise: Franchise.find_or_create_by(title: parsed_product[:franchise]),
        shape: parsed_product[:shape] || Product.default_shape
      )
      product.build_base_variant(sku: parsed_product[:sku] || "#{parsed_product[:title].parameterize}-#{rand(1000..9999)}")
      product.save! if product.new_record? || product.changed? || product.base_variant&.new_record? || product.base_variant&.changed?
      product
    end
  end

  describe ".import" do
    context "with invalid input" do
      it "raises error when parsed_order is blank" do
        expect { described_class.import({}) }.to raise_error(ArgumentError, "Parsed payload cannot be blank")
      end

      it "raises error when parsed_order is nil" do
        expect { described_class.import(nil) }.to raise_error(ArgumentError, "Parsed payload cannot be blank")
      end
    end
  end

  describe "#import" do
    context "when creating a new sale" do
      it "creates all required records" do
        import_order
        expect(Sale.count).to eq(1)
        expect(Customer.count).to eq(1)
        expect(SaleItem.count).to eq(1)
      end

      it "resolves the order's import failure when the import succeeds" do
        store_order_id = "gid://shopify/Order/failed"
        order = valid_parsed_order.deep_dup
        order[:store_info] = order[:store_info].merge(store_id: store_order_id)
        Sale::ImportFailure.record(store_name: "shopify", store_order_id:, message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

        import_order(order)

        expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id:).resolved_at).to be_present
      end

      it "keeps local sales tags when the same order is imported again" do
        order = valid_parsed_order.deep_dup
        order[:store_info] = order[:store_info].merge(store_id: "gid://shopify/Order/tagged")
        import_order(order)
        sale = Sale.last
        tag = create(:sales_tag, name: "VIP")
        SaleTagging.create!(sale:, sales_tag: tag)

        import_order(order)

        expect(Sale.pluck(:id)).to eq([sale.id])
        expect(sale.reload.sales_tags).to eq([tag])
      end

      it "associates customer with sale" do
        import_order
        expect(Sale.last.customer).to eq(Customer.last)
      end

      it "sets ext_created_at on sale shopify_info" do
        import_order
        sale = Sale.last
        expect(sale.shopify_info.ext_created_at).to be_within(1.second).of(Time.zone.parse("2025-05-01T06:27:45+00:00"))
      end

      it "persists the Shopify order timestamp on the sale for analytics" do
        import_order
        sale = Sale.last

        expect(sale.shopify_created_at).to be_within(1.second).of(Time.zone.parse("2025-05-01T06:27:45+00:00"))
      end

      it "sets ext_created_at on customer shopify_info" do
        import_order
        customer = Customer.last
        expect(customer.shopify_info.ext_created_at).to be_within(1.second).of(Time.zone.parse("2025-04-15T10:30:00+00:00"))
      end

      it "sets store_id to each entity's own shopify_id" do
        import_order
        sale = Sale.last
        customer = Customer.last

        expect(sale.shopify_info.store_id).to eq(valid_parsed_order[:sale][:shopify_id])
        expect(customer.shopify_info.store_id).to eq(valid_parsed_order[:customer][:store_info][:store_id])
      end

      it "persists shipping and billing addresses" do
        parsed_order = valid_parsed_order.deep_dup.merge(
          addresses: {
            shipping: {address_1: "Shipping St", city: "Berlin", country: "DE"},
            billing: {address_1: "Billing St", city: "Munich", country: "DE"}
          }
        )

        sale = import_order(parsed_order)

        expect(sale.shipping_address).to have_attributes(address_1: "Shipping St", city: "Berlin")
        expect(sale.billing_address).to have_attributes(address_1: "Billing St", city: "Munich")
      end

      it "persists and links a native Shopify payment plan idempotently" do
        order_id = "gid://shopify/Order/777"
        parsed_order = valid_parsed_order.deep_dup.merge(
          store_info: valid_parsed_order[:store_info].merge(store_id: order_id),
          payment_plan: {
            attributes: {
              provider: "shopify",
              external_id: "gid://shopify/PaymentTerms/77",
              external_origin_order_id: order_id,
              kind: "payment_terms",
              status: "active",
              expected_parts: 2,
              next_due_at: 1.month.from_now
            },
            parts: [
              {
                provider_part_id: "gid://shopify/PaymentSchedule/1",
                sequence: 1,
                external_order_id: order_id,
                amount: "250.00",
                provider_completed_at: 1.day.ago
              },
              {
                provider_part_id: "gid://shopify/PaymentSchedule/2",
                sequence: 2,
                external_order_id: order_id,
                amount: "250.00"
              }
            ]
          }
        )

        2.times { import_order(parsed_order) }

        plan = SalePaymentPlan.sole
        sale = Sale.find_by_shopify_id(order_id)
        expect(plan).to have_attributes(origin_sale: sale, expected_parts: 2)
        expect(plan.parts.count).to eq(2)
        expect(plan.parts.pluck(:sale_id).uniq).to eq([sale.id])
      end
    end

    context "when store_info timestamps are updated" do
      let(:modified_order_with_new_timestamps) do
        valid_parsed_order.deep_dup.tap do |order|
          order[:store_info][:ext_created_at] = 2.days.ago.iso8601
          order[:store_info][:ext_updated_at] = 30.minutes.ago.iso8601
        end
      end

      before { import_order }

      it "updates ext_created_at" do
        original_created_at = Sale.last.shopify_info.ext_created_at

        described_class.import(modified_order_with_new_timestamps)

        sale = Sale.last
        expect(sale.shopify_info.ext_created_at).not_to eq(original_created_at)
      end

      it "updates existing address snapshots" do
        described_class.import(
          valid_parsed_order.deep_dup.merge(
            addresses: {
              shipping: {address_1: "Old Shipping St", city: "Berlin"},
              billing: {address_1: "Old Billing St", city: "Munich"}
            }
          )
        )

        described_class.import(
          valid_parsed_order.deep_dup.merge(
            addresses: {
              shipping: {address_1: "New Shipping St", city: "Hamburg"},
              billing: {address_1: "New Billing St", city: "Cologne"}
            }
          )
        )

        sale = Sale.last
        expect(sale.addresses.count).to eq(2)
        expect(sale.shipping_address).to have_attributes(address_1: "New Shipping St", city: "Hamburg")
        expect(sale.billing_address).to have_attributes(address_1: "New Billing St", city: "Cologne")
      end
    end

    context "when variant already exists" do
      let!(:existing_variant) do
        create(
          :variant, :synced,
          product: create(:product, :synced, shopify_id: valid_parsed_order[:sale_items].first[:product_store_id]),
          shopify_id: valid_parsed_order[:sale_items].first[:variant_store_id]
        )
      end

      it "uses existing variant" do
        expect { import_order }.not_to change(Variant, :count)
      end
    end

    context "when the parsed order carries Shopify currency provenance" do
      let(:parsed_order_with_currency) do
        order = valid_parsed_order.deep_dup
        order[:store_info] = order[:store_info].merge(store_id: "gid://shopify/Order/currency-provenance")
        order[:sale].merge!(
          shop_currency: "EUR",
          presentment_currency: "CHF",
          usd_conversion_rate: "1.1250",
          exchange_rate_date: "2026-08-21"
        )
        order
      end

      it "persists the resolved shop currency, presentment currency, rate, and effective date" do
        described_class.import(parsed_order_with_currency)

        expect(Sale.last).to have_attributes(
          shop_currency: "EUR",
          presentment_currency: "CHF",
          usd_conversion_rate: BigDecimal("1.1250"),
          exchange_rate_date: Date.new(2026, 8, 21)
        )
      end

      it "re-importing the same raw payload updates the same sale without duplicating currency data" do
        2.times { described_class.import(parsed_order_with_currency) }

        expect(Sale.count).to eq(1)
        expect(Sale.last.usd_conversion_rate).to eq(BigDecimal("1.1250"))
      end

      it "leaves previously persisted currency data unchanged when a later import fails" do
        described_class.import(parsed_order_with_currency)
        sale = Sale.last

        allow_any_instance_of(Sale).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(Sale.new))

        expect { described_class.import(parsed_order_with_currency) }.to raise_error(Sale::Shopify::Importer::Error)

        expect(sale.reload).to have_attributes(
          shop_currency: "EUR",
          presentment_currency: "CHF",
          usd_conversion_rate: BigDecimal("1.1250"),
          exchange_rate_date: Date.new(2026, 8, 21)
        )
      end
    end

    context "when product sale is corrupted (no product info at all)" do
      let(:parsed_order_corrupted) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first[:variant_store_id] = nil
        order[:sale_items].first[:product_store_id] = nil
        order[:sale_items].first[:variant_title] = nil
        order[:sale_items].first[:full_title] = nil
        order
      end
      let(:importer_corrupted) { described_class.new(parsed_order_corrupted) }

      it "does not create a new variant when variant_title is missing" do
        expect { described_class.import(parsed_order_corrupted) }.not_to change(Variant, :count)
      end

      it "does not create sale_item when product data is completely missing" do
        expect { described_class.import(parsed_order_corrupted) }.not_to change(SaleItem, :count)
      end
    end

    context "when sale item has only full_title (no Shopify IDs)" do
      let(:parsed_order_title_only) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          variant_title: "Limited Variant",
          variant_store_id: nil,
          product_store_id: nil,
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        )
        order
      end

      it "creates product from full_title using Product::Shopify::Parser" do
        expect { described_class.import(parsed_order_title_only) }.to change(Product, :count).by(1)
        product = Product.last
        expect(product.title).to eq("Princess Leia")
        expect(product.franchise.title).to eq("Star Wars")
      end

      it "creates variant from variant_title" do
        expect { described_class.import(parsed_order_title_only) }.to change(Variant, :count).by(2)
        expect(Variant.last.version.value).to eq("Limited Variant")
      end

      it "creates sale_item with product and variant" do
        described_class.import(parsed_order_title_only)
        sale_item = SaleItem.last
        expect(sale_item.product).to be_present
        expect(sale_item.variant).to be_present
      end

      it "reuses an existing storeless product with the same parsed identity" do
        parsed_title = Product::Shopify::Parser.parse({"title" => parsed_order_title_only[:sale_items].first[:full_title]})

        existing_product = create(
          :product,
          title: parsed_title[:title],
          franchise: Franchise.find_or_create_by!(title: parsed_title[:franchise]),
          shape: parsed_title[:shape]
        ).tap do |product|
          product.store_infos.destroy_all
          product.update_columns(shopify_id: nil, woo_id: nil)
          product.reload
          Array(parsed_title[:size]).compact.each { |value| product.sizes << Size.find_or_create_by!(value:) }
          Array(parsed_title[:brand]).compact.each { |title| product.brands << Brand.find_or_create_by!(title:) }
        end

        expect { described_class.import(parsed_order_title_only) }.not_to change(Product, :count)
        expect(SaleItem.last.product).to eq(existing_product)
      end

      it "reuses the same product across different title-only sales" do
        first_order = parsed_order_title_only.deep_dup
        second_order = parsed_order_title_only.deep_dup

        first_order[:sale][:shopify_id] = "gid://shopify/Order/title-only-1"
        first_order[:store_info][:store_id] = "gid://shopify/Order/title-only-1"
        first_order[:sale_items].first[:store_id] = "gid://shopify/LineItem/title-only-1"

        second_order[:sale][:shopify_id] = "gid://shopify/Order/title-only-2"
        second_order[:store_info][:store_id] = "gid://shopify/Order/title-only-2"
        second_order[:sale_items].first[:store_id] = "gid://shopify/LineItem/title-only-2"

        allow(Product::Shopify::Importer).to receive(:import).and_call_original
        allow(Shopify::PullVariantsJob).to receive(:perform_later)
        allow(Shopify::ImportMediaJob).to receive(:perform_later)

        expect {
          described_class.import(first_order)
          described_class.import(second_order)
        }.to change(Product, :count).by(1)
          .and change(Sale, :count).by(2)
          .and change(SaleItem, :count).by(2)

        expect(Sale.order(:id).last(2).map { |sale| sale.sale_items.last.product_id }.uniq.count).to eq(1)
      end

      it "creates a sale item against Base when variant_title is blank" do
        parsed_order_without_variant_title = parsed_order_title_only.deep_dup
        parsed_order_without_variant_title[:sale_items].first[:variant_title] = nil
        parsed_order_without_variant_title[:sale_items].first[:store_id] = "gid://shopify/LineItem/title-only-no-variant"
        parsed_order_without_variant_title[:sale][:shopify_id] = "gid://shopify/Order/title-only-no-variant"
        parsed_order_without_variant_title[:store_info][:store_id] = "gid://shopify/Order/title-only-no-variant"

        allow(Product::Shopify::Importer).to receive(:import).and_call_original
        allow(Shopify::PullVariantsJob).to receive(:perform_later)
        allow(Shopify::ImportMediaJob).to receive(:perform_later)

        expect {
          described_class.import(parsed_order_without_variant_title)
        }.to change(SaleItem, :count).by(1)
          .and change(Variant, :count).by(1)

        sale_item = SaleItem.last
        expect(sale_item.product).to be_present
        expect(sale_item.variant).to eq(sale_item.product.base_variant)
      end
    end

    context "when a sale item only has full_title but still includes product_store_id" do
      let(:parsed_order_with_store_id_and_title_only) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          variant_title: "Limited Variant",
          variant_store_id: nil,
          product_store_id: "gid://shopify/Product/title-rebuilt",
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        )
        order
      end

      before do
        allow(Shopify::PullVariantsJob).to receive(:perform_later)
        allow(Shopify::ImportMediaJob).to receive(:perform_later)
        allow(Product::Shopify::Importer).to receive(:import).and_call_original
      end

      it "creates a product linked to the known Shopify store id" do
        described_class.import(parsed_order_with_store_id_and_title_only)

        sale_item = SaleItem.last
        expect(sale_item.product).to be_present
        expect(sale_item.product.shopify_info.store_id).to eq("gid://shopify/Product/title-rebuilt")
      end

      it "fetches the product once and enqueues no product pull when Shopify no longer returns it" do
        described_class.import(parsed_order_with_store_id_and_title_only)

        expect(api_client).to have_received(:fetch_product).with("gid://shopify/Product/title-rebuilt").once
        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end
    end

    context "when a Shopify product reference cannot be resolved" do
      let(:parsed_order_with_unresolved_product) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          product_store_id: "gid://shopify/Product/missing-product",
          full_title: nil
        )
        order
      end

      it "creates the sale item with a placeholder product instead of crashing" do
        expect {
          described_class.import(parsed_order_with_unresolved_product)
        }.to change(Sale, :count).by(1)
          .and change(SaleItem, :count).by(1)
          .and change(Product, :count).by(1)

        sale_item = SaleItem.last
        expect(sale_item.product.shopify_info.store_id).to eq("gid://shopify/Product/missing-product")
        expect(sale_item.product.title).to include("[BROKEN SHOPIFY PRODUCT]")
      end
    end

    context "when creating new variant with custom title" do
      let(:parsed_order_with_new_variant) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          variant_title: "New Variant",
          variant_store_id: nil,
          product_store_id: "gid://shopify/Product/999999",
          variant_title_from_product: "Regular"
        )
        order
      end

      let(:product) { create(:product, :synced, shopify_id: "gid://shopify/Product/999999") }
      let(:variant) { create(:variant, product: product) }

      before do
        allow(Product::Shopify::Importer).to receive(:import).and_return(product)
        allow(Version).to receive(:find_or_create_by).with(value: "New Variant").and_return(variant.version)
        allow(variant.version).to receive(:value).and_return("New Variant")
      end

      it "creates new variant with correct title" do
        expect { described_class.import(parsed_order_with_new_variant) }.to change(Variant, :count).by(1)
        expect(Variant.last.version.value).to eq("New Variant")
      end
    end

    context "when creating variant with multiple custom attributes" do
      let(:parsed_order_with_complex_variant) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          variant_title: "1:4 | New Variant | Red",
          variant_store_id: nil,
          product_store_id: "gid://shopify/Product/888888",
          variant_title_from_product: "Regular"
        )
        order
      end

      let(:product) { create(:product, :synced, shopify_id: "gid://shopify/Product/888888") }
      let(:variant) { create(:variant, product: product) }

      before do
        allow(Product::Shopify::Importer).to receive(:import).and_return(product)
        allow(Version).to receive(:find_or_create_by).with(value: "1:4 | New Variant | Red").and_return(variant.version)
        allow(variant.version).to receive(:value).and_return("1:4 | New Variant | Red")
      end

      it "creates new variant with multiple attributes" do
        expect { described_class.import(parsed_order_with_complex_variant) }.to change(Variant, :count).by(1)
        expect(Variant.last.version.value).to eq("1:4 | New Variant | Red")
      end
    end

    context "when a sale item cannot be saved" do
      let(:product) { create(:product, :synced, shopify_id: "gid://shopify/Product/67890") }
      let(:parsed_order_with_invalid_item) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          variant_title: nil,
          variant_store_id: nil,
          product_store_id: product.shopify_info.store_id,
          full_title: nil
        )
        order
      end

      before { create(:variant, :with_version, product:) }

      it "leaves the order's import failure unresolved when the import rolls back" do
        store_order_id = "gid://shopify/Order/failed"
        order = parsed_order_with_invalid_item.deep_dup
        order[:store_info] = order[:store_info].merge(store_id: store_order_id)
        Sale::ImportFailure.record(store_name: "shopify", store_order_id:, message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

        expect { described_class.import(order) }.to raise_error(described_class::Error, /Variant must be selected/)

        expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id:).resolved_at).to be_nil
      end

      it "rolls back the sale and its customer" do
        expect {
          begin
            described_class.import(parsed_order_with_invalid_item)
          rescue described_class::Error
            nil
          end
        }.not_to change { [Sale.count, Customer.count, SaleItem.count] }
      end
    end

    context "when there are errors" do
      let(:store_info) { instance_double(StoreInfo, assign_attributes: true, save!: true) }

      before do
        allow(Sale).to receive_messages(find_by_shopify_id: nil, new: Sale.new)
        allow_any_instance_of(Sale).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(Sale.new))
        allow_any_instance_of(Sale).to receive(:shopify_info).and_return(store_info)
        allow_any_instance_of(Sale).to receive(:store_infos).and_return(double(shopify: store_info))
      end

      it "rolls back all changes" do
        expect { import_order }.to raise_error(Sale::Shopify::Importer::Error)
        expect {
          begin
            import_order
          rescue
            nil
          end
        }.not_to change(Sale, :count)
      end
    end

    context "when customer already exists" do
      let!(:existing_customer) do
        customer = create(:customer,
          email: "old_email@example.com",
          first_name: "OldFirstName",
          last_name: "OldLastName",
          phone: "1234567890")
        customer.store_infos.create(store_name: :shopify, store_id: valid_parsed_order[:customer][:store_info][:store_id])
        customer
      end

      it "updates existing customer with new data" do
        expect { import_order }.not_to change(Customer, :count)

        existing_customer.reload
        expect(existing_customer.first_name).to eq(valid_parsed_order[:customer][:first_name])
      end
    end

    context "when product already exists" do
      let(:existing_product) do
        create(:product, :synced,
          shopify_id: valid_parsed_order[:sale_items].first[:product_store_id],
          title: "Old Product Title")
      end

      it "uses existing product" do
        existing_product
        expect { import_order }.not_to change(Product, :count)
      end
    end

    context "when sale_item already exists" do
      let!(:existing_sale) { create(:sale, :synced, shopify_id: valid_parsed_order[:sale][:store_id]) }
      let!(:existing_sale_item) do
        product = create(:product, :synced, shopify_id: valid_parsed_order[:sale_items].first[:product_store_id])
        variant = create(
          :variant, :synced,
          product:,
          shopify_id: valid_parsed_order[:sale_items].first[:variant_store_id]
        )

        create(:sale_item, :synced,
          shopify_id: valid_parsed_order[:sale_items].first[:store_id],
          price: "500.00",
          qty: 1,
          sale: existing_sale,
          product: product,
          variant: variant)
      end

      it "updates existing sale_item with new data" do
        modified_order = valid_parsed_order.deep_dup
        modified_order[:sale_items].first[:price] = "600.00"

        described_class.import(modified_order)

        expect { existing_sale_item.reload }.to change(existing_sale_item, :price).to(BigDecimal("600.00"))
      end
    end

    context "when importing Shopify payment data" do
      let(:parsed_order_with_revenue) do
        order = valid_parsed_order.deep_dup
        order[:sale].merge!(
          expected_revenue: "234.63",
          received_revenue: "100.00",
          outstanding_revenue: "134.63",
          refunded_revenue: "0.00",
          net_payment: "100.00",
          payment_gateway_names: ["shopify_payments"],
          payment_terms_name: "Within 30 days",
          payment_terms_type: "NET",
          payment_due: "2025-06-01T00:00:00+00:00",
          payment_overdue: true
        )
        order[:sale_items].first[:expected_revenue] = "234.63"
        order
      end

      it "persists sale-level revenue and payment terms fields" do
        described_class.import(parsed_order_with_revenue)

        expect(Sale.last).to have_attributes(
          expected_revenue: BigDecimal("234.63"),
          received_revenue: BigDecimal("100.00"),
          outstanding_revenue: BigDecimal("134.63"),
          refunded_revenue: BigDecimal(0),
          net_payment: BigDecimal("100.00"),
          payment_gateway_names: ["shopify_payments"],
          payment_terms_name: "Within 30 days",
          payment_terms_type: "NET",
          payment_overdue: true
        )
        expect(Sale.last.payment_due).to be_within(1.second).of(Time.zone.parse("2025-06-01T00:00:00+00:00"))
      end

      it "allocates the full order revenue to a single sale item" do
        described_class.import(parsed_order_with_revenue)

        expect(SaleItem.last).to have_attributes(
          expected_revenue: BigDecimal("234.63"),
          received_revenue: BigDecimal("100.00"),
          outstanding_revenue: BigDecimal("134.63"),
          refunded_revenue: BigDecimal(0)
        )
      end

      it "imports a line whose Shopify variant is not linked on a product with real variants and allocates its revenue" do
        line = parsed_order_with_revenue[:sale_items].first
        product = create(:product, :synced, shopify_id: line[:product_store_id])
        create(:variant, :with_version, product:)

        expect { described_class.import(parsed_order_with_revenue) }.to change(SaleItem, :count).by(1)

        expect(SaleItem.sole).to have_attributes(
          variant: product.variants.base_models.first,
          shopify_variant_id: line[:variant_store_id],
          expected_revenue: BigDecimal("234.63"),
          received_revenue: BigDecimal("100.00"),
          outstanding_revenue: BigDecimal("134.63"),
          refunded_revenue: BigDecimal(0)
        )
        expect(Sale.last).to be_shopify_variant_unlinked
        expect(Sale.last.sales_tags).to be_empty
        expect(SalesTag.count).to eq(0)
      end

      it "allocates order revenue proportionally across multiple line items" do
        order = parsed_order_with_revenue.deep_dup
        order[:sale].merge!(
          expected_revenue: "300.00",
          received_revenue: "90.00",
          outstanding_revenue: "210.00",
          refunded_revenue: "0.00"
        )
        order[:sale_items].first[:expected_revenue] = "100.00"

        second_item = order[:sale_items].first.deep_dup
        second_item.merge!(
          store_id: "gid://shopify/LineItem/second-item",
          variant_store_id: nil,
          variant_title: nil,
          product_store_id: "gid://shopify/Product/second-product",
          full_title: "Halo - Master Chief | 1:4 Resin Statue",
          expected_revenue: "200.00"
        )
        order[:sale_items] << second_item

        described_class.import(order)

        first_item = SaleItem.find_by(shopify_id: order[:sale_items].first[:store_id])
        allocated_second_item = SaleItem.find_by(shopify_id: "gid://shopify/LineItem/second-item")

        expect(first_item).to have_attributes(
          received_revenue: BigDecimal(30),
          outstanding_revenue: BigDecimal(70)
        )
        expect(allocated_second_item).to have_attributes(
          received_revenue: BigDecimal(60),
          outstanding_revenue: BigDecimal(140)
        )
      end

      it "leaves revenue fields empty when the payload has no payment data" do
        import_order

        expect(Sale.last).to have_attributes(
          received_revenue: nil,
          outstanding_revenue: nil,
          refunded_revenue: nil
        )
        expect(SaleItem.last).to have_attributes(received_revenue: nil, outstanding_revenue: nil)
      end
    end

    context "when the sale holds a saved item without a variant" do
      let(:store_order_id) { "gid://shopify/Order/nil-variant" }
      let(:existing_sale) { create(:sale, shopify_store_id: store_order_id) }
      let(:product) { create(:product) }
      let!(:saved_item) { create(:sale_item, sale: existing_sale, product:, expected_revenue: BigDecimal(100)) }
      let(:order) do
        valid_parsed_order.deep_dup.tap do |parsed_order|
          parsed_order[:store_info] = parsed_order[:store_info].merge(store_id: store_order_id)
          parsed_order[:sale].merge!(
            expected_revenue: "100.00",
            received_revenue: "100.00",
            outstanding_revenue: "0.00",
            refunded_revenue: "0.00"
          )
          parsed_order[:sale_items] = []
        end
      end

      before do
        create(:variant, product:)
        saved_item.update_column(:variant_id, nil) # rubocop:disable Rails/SkipsModelValidations
      end

      it "imports the order and allocates the item's revenue without choosing a variant" do
        import_order(order)

        expect(saved_item.reload).to have_attributes(received_revenue: BigDecimal(100), variant_id: nil)
      end
    end

    context "when linking purchased products" do
      let(:product) { create(:product) }
      let(:purchase_variant) do
        variant = create(:variant, :with_version, product:)
        variant.upsert_shopify_info(
          store_id: valid_parsed_order[:sale_items].first[:variant_store_id]
        )
        variant
      end
      let(:purchase) { create(:purchase, product:, variant: purchase_variant, amount: 3) }
      let!(:purchase_items) { create_list(:purchase_item, 3, purchase: purchase) }
      let!(:existing_sale) do
        sale = create(:sale, :synced, status: "pre-ordered")
        sale.update!(shopify_id: valid_parsed_order[:sale][:store_id])
        sale.shopify_info.update(store_id: valid_parsed_order[:store_info][:store_id])
        sale
      end
      let(:sale_item) do
        create(
          :sale_item,
          sale: existing_sale,
          product:,
          variant: purchase_variant,
          qty: 2
        )
      end
      let(:sale_item_store_id_from_fixture) { valid_parsed_order[:sale_items].first[:store_id] }

      before do
        existing_sale
        sale_item.update(shopify_id: sale_item_store_id_from_fixture)

        sale_item.update(purchase_items_count: 0)

        allow(Product::Shopify::Importer).to receive(:import).and_return(product)
      end

      it "records a pending link intent for each linked purchase item" do
        order_with_email = valid_parsed_order.deep_merge(customer: {email: "jimmy@example.com"})

        expect { import_order(order_with_email) }.to have_enqueued_job(OutboundEmailDeliveryJob).at_least(:once)

        expect(OutboundEmail.where(source: "link", state: "pending", recipient: "jimmy@example.com", purchase_item_id: purchase_items.map(&:id))).to be_present
      end
    end

    context "when a line references a product or variant that is not cached locally" do
      let(:product_store_id) { "gid://shopify/Product/9118444224841" }
      let(:variant_store_id) { "gid://shopify/ProductVariant/50195649364297" }
      let(:other_variant_store_id) { "gid://shopify/ProductVariant/50195649397065" }
      let(:shopify_product) do
        {
          "id" => product_store_id,
          "title" => "Star Wars - Princess Leia | 1:4 Resin Statue | by von xionart",
          "handle" => "star-wars-princess-leia",
          "tags" => [],
          "createdAt" => "2025-01-01T00:00:00Z",
          "updatedAt" => "2025-01-02T00:00:00Z",
          "media" => {"nodes" => [{"id" => "gid://shopify/MediaImage/1", "alt" => "Front", "image" => {"url" => "https://cdn.shopify.com/leia.jpg"}}]},
          "variants" => {
            "edges" => [
              {"node" => {"id" => variant_store_id, "title" => "Big Chest", "sku" => "leia-big", "selectedOptions" => [{"name" => "Version", "value" => "Big Chest"}]}},
              {"node" => {"id" => other_variant_store_id, "title" => "Normal Chest", "sku" => "leia-normal", "selectedOptions" => [{"name" => "Version", "value" => "Normal Chest"}]}}
            ]
          }
        }
      end
      let(:single_variant_product) do
        shopify_product.merge(
          "variants" => {"edges" => [{"node" => {"id" => variant_store_id, "title" => "Default Title", "sku" => "leia-only", "selectedOptions" => [{"name" => "Title", "value" => "Default Title"}]}}]}
        )
      end
      let(:order) do
        valid_parsed_order.deep_dup.tap do |parsed_order|
          parsed_order[:store_info] = parsed_order[:store_info].merge(store_id: "gid://shopify/Order/uncached")
          parsed_order[:sale_items] = [line("gid://shopify/LineItem/uncached-1", variant_store_id:, variant_title: "Big Chest")]
        end
      end

      def line(store_id, variant_store_id:, variant_title:, product_store_id: self.product_store_id)
        {
          store_id:,
          qty: 1,
          price: "159.41",
          expected_revenue: "159.41",
          product_store_id:,
          variant_store_id:,
          variant_title:,
          full_title: "Star Wars - Princess Leia | 1:4 Resin Statue | von xionart"
        }
      end

      before do
        allow(Product::Shopify::Importer).to receive(:import).and_call_original
        allow(Shopify::PullVariantsJob).to receive(:perform_later)
        allow(Shopify::ImportMediaJob).to receive(:perform_later)
        allow(api_client).to receive(:fetch_product).with(product_store_id).and_return(shopify_product)
      end

      it "imports the product and its variants before the sale items, so the first pass saves the line on its own variant" do
        import_order(order)

        sale_item = SaleItem.sole
        expect(sale_item.product.shopify_info.store_id).to eq(product_store_id)
        expect(sale_item.variant.shopify_info.store_id).to eq(variant_store_id)
        expect(sale_item.variant.version.value).to eq("Big Chest")
        expect(Variant.find_by_shopify_id(other_variant_store_id)).to be_present
      end

      it "leaves the product's variants out of the queue and its media queued" do
        import_order(order)

        product = Product.find_by_shopify_id(product_store_id)
        expect(Shopify::PullVariantsJob).not_to have_received(:perform_later)
        expect(Shopify::ImportMediaJob).to have_received(:perform_later)
          .with(product, [hash_including(id: "gid://shopify/MediaImage/1", url: "https://cdn.shopify.com/leia.jpg")])
      end

      it "never enqueues a product pull" do
        import_order(order)

        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end

      it "fetches a product once when several lines reference it" do
        two_lines = order.deep_dup
        two_lines[:sale_items] = [
          line("gid://shopify/LineItem/uncached-1", variant_store_id:, variant_title: "Big Chest"),
          line("gid://shopify/LineItem/uncached-2", variant_store_id: other_variant_store_id, variant_title: "Normal Chest"),
          line("gid://shopify/LineItem/uncached-3", variant_store_id:, variant_title: "Big Chest")
        ]

        import_order(two_lines)

        expect(api_client).to have_received(:fetch_product).once
        expect(SaleItem.pluck(:shopify_id)).to contain_exactly(
          "gid://shopify/LineItem/uncached-1", "gid://shopify/LineItem/uncached-2", "gid://shopify/LineItem/uncached-3"
        )
      end

      it "fetches each distinct missing product once" do
        second_product_store_id = "gid://shopify/Product/second"
        two_products = order.deep_dup
        two_products[:sale_items] = [
          line("gid://shopify/LineItem/uncached-1", variant_store_id:, variant_title: "Big Chest"),
          line("gid://shopify/LineItem/uncached-2", variant_store_id: nil, variant_title: nil, product_store_id: second_product_store_id)
        ]

        import_order(two_products)

        expect(api_client).to have_received(:fetch_product).with(product_store_id).once
        expect(api_client).to have_received(:fetch_product).with(second_product_store_id).once
      end

      it "fetches nothing when the line's product and variant are cached" do
        product = create(:product, :synced, shopify_id: product_store_id)
        create(:variant, :synced, product:, shopify_id: variant_store_id)

        import_order(order)

        expect(Shopify::Api::Client).not_to have_received(:new)
        expect(SaleItem.sole.variant.shopify_info.store_id).to eq(variant_store_id)
      end

      it "fetches a cached product when the line's variant is not cached" do
        create(:product, :synced, shopify_id: product_store_id)

        import_order(order)

        expect(api_client).to have_received(:fetch_product).with(product_store_id).once
        expect(SaleItem.sole.variant.shopify_info.store_id).to eq(variant_store_id)
      end

      it "fetches a product when its line has no variant" do
        allow(api_client).to receive(:fetch_product).with(product_store_id).and_return(single_variant_product)
        product_only = order.deep_dup
        product_only[:sale_items] = [line("gid://shopify/LineItem/uncached-1", variant_store_id: nil, variant_title: nil)]

        import_order(product_only)

        expect(api_client).to have_received(:fetch_product).with(product_store_id).once
        expect(SaleItem.sole.product.shopify_info.store_id).to eq(product_store_id)
      end

      it "fetches nothing for a line without a Shopify product" do
        title_only = order.deep_dup
        title_only[:sale_items] = [line("gid://shopify/LineItem/uncached-1", variant_store_id: nil, variant_title: nil, product_store_id: nil)]

        import_order(title_only)

        expect(Shopify::Api::Client).not_to have_received(:new)
      end

      it "saves the line on the product's base variant when the fetched product does not carry its variant" do
        orphan_line = order.deep_dup
        orphan_line[:sale_items] = [line("gid://shopify/LineItem/uncached-1", variant_store_id: "gid://shopify/ProductVariant/gone", variant_title: "Gone")]
        allow(api_client).to receive(:fetch_product).with(product_store_id).and_return(single_variant_product)

        import_order(orphan_line)

        sale_item = SaleItem.sole
        expect(sale_item.variant).to eq(sale_item.product.base_variant)
        expect(sale_item.variant).to be_base_model
      end

      it "creates the same placeholder as before when Shopify no longer returns the product" do
        allow(api_client).to receive(:fetch_product).with(product_store_id).and_return(nil)
        placeholder_line = order.deep_dup
        placeholder_line[:sale_items] = [line("gid://shopify/LineItem/uncached-1", variant_store_id: nil, variant_title: nil).merge(full_title: nil)]

        expect { import_order(placeholder_line) }.to change(SaleItem, :count).by(1).and change(Product, :count).by(1)

        product = SaleItem.sole.product
        expect(product.shopify_info.store_id).to eq(product_store_id)
        expect(product.title).to include("[BROKEN SHOPIFY PRODUCT]")
        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end

      it "creates the same title-only product as before when Shopify no longer returns the product" do
        allow(api_client).to receive(:fetch_product).with(product_store_id).and_return(nil)

        import_order(order)

        product = SaleItem.sole.product
        expect(product.shopify_info.store_id).to eq(product_store_id)
        expect(product.title).to eq("Princess Leia")
        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end

      it "fetches and imports outside the sale transaction" do
        baseline = ActiveRecord::Base.connection.open_transactions
        depths = {}
        allow(api_client).to receive(:fetch_product) do
          depths[:fetch] = ActiveRecord::Base.connection.open_transactions
          shopify_product
        end
        allow(Product::Shopify::Importer).to receive(:import).and_wrap_original do |original, *args, **options|
          depths[:product_import] = ActiveRecord::Base.connection.open_transactions
          original.call(*args, **options)
        end
        allow(Variant::Shopify::Importer).to receive(:import_all).and_wrap_original do |original, *args|
          depths[:variants_import] = ActiveRecord::Base.connection.open_transactions
          original.call(*args)
        end

        import_order(order)

        expect(depths).to eq(fetch: baseline, product_import: baseline, variants_import: baseline)
      end

      it "fails only that order when Shopify rejects the product query" do
        allow(api_client).to receive(:fetch_product).and_raise(Shopify::Api::Client::ApiError, "Failed to fetch product: Access denied")

        expect { import_order(order) }.to raise_error(described_class::Error) { |error|
          expect(error.message).to start_with("Failed to import product #{product_store_id}: Failed to fetch product: Access denied\n")
          expect(error.message).to include("sale_store_id: gid://shopify/Order/uncached")
        }

        expect(Sale.count).to eq(0)
      end

      it "fails only that order when the fetched product does not import" do
        allow(Product::Shopify::Importer).to receive(:import).and_raise(Product::Shopify::Importer::Error, "Failed to process Product: Title can't be blank")

        expect { import_order(order) }.to raise_error(
          described_class::Error,
          /\AFailed to import product #{product_store_id}: Failed to process Product: Title can't be blank\n/
        )

        expect(Sale.count).to eq(0)
      end

      it "fails only that order when the fetched product's variants do not import" do
        allow(Variant::Shopify::Importer).to receive(:import).and_raise(ActiveRecord::RecordInvalid.new(Variant.new))

        expect { import_order(order) }.to raise_error(
          described_class::Error,
          /\AFailed to import product #{product_store_id}: .*product_shopify_id: #{product_store_id}/m
        )

        expect(Sale.count).to eq(0)
      end

      it "leaves the order's import failure unresolved when the fetch fails" do
        store_order_id = "gid://shopify/Order/uncached"
        Sale::ImportFailure.record(store_name: "shopify", store_order_id:, message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)
        allow(api_client).to receive(:fetch_product).and_raise(Shopify::Api::Client::ApiError, "Failed to fetch product")

        expect { import_order(order) }.to raise_error(described_class::Error)

        expect(Sale::ImportFailure.find_by!(store_name: "shopify", store_order_id:).resolved_at).to be_nil
      end

      it "re-raises a throttled fetch so the job retries instead of failing the order" do
        allow(api_client).to receive(:fetch_product).and_raise(Shopify::Api::Client::Throttled, "Shopify throttled product")

        expect { import_order(order) }.to raise_error(Shopify::Api::Client::Throttled)

        expect(Sale.count).to eq(0)
      end
    end
  end
end
