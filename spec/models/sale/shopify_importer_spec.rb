# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::ShopifyImporter, :aggregate_failures do
  let(:parsed_orders) { instance_eval(file_fixture("shopify_parsed_orders.rb").read) }
  let(:valid_parsed_order) { parsed_orders.first }
  let(:importer) { described_class.new(valid_parsed_order) }

  before do
    # Use local hash to track created editions and avoid uniqueness violations
    created_editions = {}

    # Stub Product::ShopifyImporter to create valid products with SKUs
    allow(Product::ShopifyImporter).to receive(:import!) do |parsed_product|
      product = Product.find_by_shopify_id(parsed_product[:shopify_id]) || Product.new
      product.assign_attributes(
        title: parsed_product[:title],
        franchise: Franchise.find_or_create_by(title: parsed_product[:franchise]),
        shape: Shape.find_or_create_by(title: parsed_product[:shape] || "Statue"),
        sku: parsed_product[:sku] || "#{parsed_product[:title].parameterize}-#{rand(1000..9999)}"
      )
      product.save!
      product
    end

    # Stub Edition::ShopifyImporter to return unique editions
    allow(Edition::ShopifyImporter).to receive(:import!) do |product, parsed_edition|
      edition_key = "#{product.id}-#{parsed_edition[:id]}"
      created_editions[edition_key] ||= begin
        edition = Edition.find_by_shopify_id(parsed_edition[:id]) || Edition.new(product: product)
        edition.version = Version.find_or_create_by(value: parsed_edition[:title] || "Default")
        edition.save!
        edition
      end
    end
  end

  describe ".import!" do
    context "with invalid input" do
      it "raises error when parsed_order is blank" do
        expect { described_class.import!({}) }.to raise_error(ArgumentError, "Parsed payload cannot be blank")
      end

      it "raises error when parsed_order is nil" do
        expect { described_class.import!(nil) }.to raise_error(ArgumentError, "Parsed payload cannot be blank")
      end
    end
  end

  describe "#import!" do
    context "when creating a new sale" do
      it "creates all required records" do
        importer.import!
        expect(Sale.count).to eq(1)
        expect(Customer.count).to eq(1)
        expect(SaleItem.count).to eq(1)
      end

      it "associates customer with sale" do
        importer.import!
        expect(Sale.last.customer).to eq(Customer.last)
      end

      it "sets ext_created_at on sale shopify_info" do
        importer.import!
        sale = Sale.last
        expect(sale.shopify_info.ext_created_at).to be_within(1.second).of(Time.zone.parse("2025-05-01T06:27:45+00:00"))
      end

      it "sets ext_created_at on customer shopify_info" do
        importer.import!
        customer = Customer.last
        expect(customer.shopify_info.ext_created_at).to be_within(1.second).of(Time.zone.parse("2025-04-15T10:30:00+00:00"))
      end

      it "sets store_id to each entity's own shopify_id" do
        importer.import!
        sale = Sale.last
        customer = Customer.last

        expect(sale.shopify_info.store_id).to eq(valid_parsed_order[:sale][:shopify_id])
        expect(customer.shopify_info.store_id).to eq(valid_parsed_order[:customer][:shopify_id])
      end
    end

    context "when sale already exists" do
      before { importer.import! }

      it "updates existing records instead of creating new ones" do
        expect { importer.import! }.not_to change(Sale, :count)
        expect { importer.import! }.not_to change(Customer, :count)
      end

      it "updates existing sale with new data" do
        modified_order = valid_parsed_order.deep_dup
        modified_order[:sale][:status] = "completed"

        described_class.new(modified_order).import!

        sale = Sale.find_by(shopify_id: valid_parsed_order[:sale][:shopify_id])
        expect(sale.status).to eq("completed")
      end
    end

    context "when store_info timestamps are updated" do
      let(:modified_order_with_new_timestamps) do
        valid_parsed_order.deep_dup.tap do |order|
          order[:store_info][:ext_created_at] = 2.days.ago.iso8601
          order[:store_info][:ext_updated_at] = 30.minutes.ago.iso8601
        end
      end

      before { importer.import! }

      it "updates ext_created_at" do
        original_created_at = Sale.last.shopify_info.ext_created_at

        described_class.new(modified_order_with_new_timestamps).import!

        sale = Sale.last
        expect(sale.shopify_info.ext_created_at).not_to eq(original_created_at)
      end
    end

    context "when edition already exists" do
      let!(:existing_edition) do
        create(:edition, shopify_id: valid_parsed_order[:sale_items].first[:shopify_edition_id])
      end

      it "uses existing edition" do
        expect { importer.import! }.not_to change(Edition, :count)
      end
    end

    context "when product sale is corrupted" do
      let(:parsed_order_corrupted) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first[:shopify_edition_id] = nil
        order[:sale_items].first[:shopify_product_id] = nil
        order[:sale_items].first[:edition_title] = nil
        order
      end
      let(:importer_corrupted) { described_class.new(parsed_order_corrupted) }

      it "does not create a new edition when edition_title is missing" do
        expect { importer_corrupted.import! }.not_to change(Edition, :count)
      end

      it "creates the product sale without a edition" do
        expect { importer_corrupted.import! }.to change(SaleItem, :count).by(1)
      end
    end

    context "when creating new edition" do
      let(:parsed_order_with_new_edition) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          edition_title: "New Edition",
          shopify_edition_id: nil,
          shopify_product_id: nil,
          full_title: "Test Product",
          product: nil
        )
        order
      end
      let(:importer_with_new_edition) { described_class.new(parsed_order_with_new_edition) }
      let(:product) { create(:product) }

      before do
        product_creator = instance_double(Shopify::ProductFromTitleCreator)
        allow(Shopify::ProductFromTitleCreator).to receive(:new).and_return(product_creator)
        allow(product_creator).to receive(:call).and_return(product)
      end

      it "creates new edition with correct title" do
        expect { importer_with_new_edition.import! }.to change(Edition, :count).by(1)
        expect(Edition.last.version.value).to eq("New Edition")
      end
    end

    context "when creating edition with multiple attributes" do
      let(:parsed_order_with_complex_edition) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          edition_title: "1:4 | New Edition | Red",
          shopify_edition_id: nil,
          shopify_product_id: nil,
          full_title: "Test Product",
          product: nil
        )
        order
      end
      let(:importer_with_complex_edition) { described_class.new(parsed_order_with_complex_edition) }
      let(:product) { create(:product) }

      before do
        product_creator = instance_double(Shopify::ProductFromTitleCreator)
        allow(Shopify::ProductFromTitleCreator).to receive(:new).and_return(product_creator)
        allow(product_creator).to receive(:call).and_return(product)
      end

      it "creates new edition with multiple attributes" do
        expect { importer_with_complex_edition.import! }.to change(Edition, :count).by(1)
        expect(Edition.last.title).to eq("1:4 | New Edition | Red")
      end
    end

    context "when edition creation fails" do
      let(:parsed_order_with_invalid_edition) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          edition_title: "Invalid Edition",
          shopify_edition_id: "gid://shopify/ProductVariant/12345",
          shopify_product_id: "gid://shopify/Product/67890",
          product: {
            title: "Test Product",
            editions: [{
              id: "gid://shopify/ProductVariant/12345",
              title: "Invalid Edition"
            }]
          }
        )
        order
      end
      let(:importer_with_invalid_edition) { described_class.new(parsed_order_with_invalid_edition) }
      let(:product) { create(:product) }

      before do
        allow(Product::ShopifyImporter).to receive(:import!).and_return(product)
        allow(Edition::ShopifyImporter).to receive(:import!).and_raise(ActiveRecord::RecordInvalid.new(Edition.new))
      end

      it "rolls back all changes when edition creation fails" do
        expect { importer_with_invalid_edition.import! }.to raise_error(Sale::ShopifyImporter::ImportError)
        expect {
          begin
            importer_with_invalid_edition.import!
          rescue
            nil
          end
        }.not_to change(Edition, :count)
      end
    end

    context "when there are errors" do
      let(:sale) { instance_double(Sale, save!: true) }

      before do
        allow(Sale).to receive(:find_by_shopify_id).and_return(sale)
        allow(sale).to receive(:assign_attributes)
        allow(sale).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Sale.new))
      end

      it "rolls back all changes" do
        expect { importer.import! }.to raise_error(Sale::ShopifyImporter::ImportError)
        expect {
          begin
            importer.import!
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
        customer.store_infos.create(store_name: :shopify, store_id: valid_parsed_order[:customer][:shopify_id])
        customer
      end

      it "updates existing customer with new data" do
        expect { importer.import! }.not_to change(Customer, :count)

        existing_customer.reload
        expect(existing_customer.first_name).to eq(valid_parsed_order[:customer][:first_name])
      end
    end

    context "when product already exists" do
      let(:existing_product) do
        create(:product,
          shopify_id: valid_parsed_order[:sale_items].first[:shopify_product_id],
          title: "Old Product Title")
      end

      it "uses existing product" do
        existing_product # Reference to ensure creation
        expect { importer.import! }.not_to change(Product, :count)
      end
    end

    context "when sale_item already exists" do
      let!(:existing_sale) { create(:sale, shopify_id: valid_parsed_order[:sale][:shopify_id]) }
      let!(:existing_sale_item) do
        product = create(:product, shopify_id: valid_parsed_order[:sale_items].first[:shopify_product_id])
        edition = create(:edition, shopify_id: valid_parsed_order[:sale_items].first[:shopify_edition_id])

        create(:sale_item,
          shopify_id: valid_parsed_order[:sale_items].first[:shopify_id],
          price: "500.00",
          qty: 1,
          sale: existing_sale,
          product: product,
          edition: edition)
      end

      it "updates existing sale_item with new data" do
        modified_order = valid_parsed_order.deep_dup
        modified_order[:sale_items].first[:price] = "600.00"

        described_class.new(modified_order).import!

        expect { existing_sale_item.reload }.to change(existing_sale_item, :price).to(BigDecimal("600.00"))
      end
    end

    context "when linking purchased products" do
      let(:product) { create(:product) }
      let(:purchase) { create(:purchase, product: product, amount: 3) }
      let!(:purchase_items) { create_list(:purchase_item, 3, purchase: purchase) }
      let!(:existing_sale) do
        sale = create(:sale, shopify_id: valid_parsed_order[:sale][:shopify_id])
        sale.shopify_info.update(store_id: valid_parsed_order[:sale][:shopify_id])
        sale
      end
      let(:sale_item) { create(:sale_item, sale: existing_sale, product: product, qty: 2) }

      before { existing_sale }

      it "notifies customers about linked products" do
        allow(PurchasedNotifier).to receive(:handle_product_purchase)
        importer.import!
        expect(PurchasedNotifier).to have_received(:handle_product_purchase)
      end
    end
  end
end
