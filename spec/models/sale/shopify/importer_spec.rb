# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Shopify::Importer, :aggregate_failures do
  let(:parsed_orders) { instance_eval(file_fixture("shopify_parsed_orders.rb").read) }
  let(:valid_parsed_order) { parsed_orders.first }
  let(:importer) { described_class.new(valid_parsed_order) }

  def import_order(parsed_order = valid_parsed_order)
    described_class.import!(parsed_order)
  end

  before do
    # Use local hash to track created editions and avoid uniqueness violations
    created_editions = {}

    # Stub Product::Shopify::Importer to create valid products with SKUs
    # Also return existing products if they match by shopify_id
    allow(Product::Shopify::Importer).to receive(:import!) do |parsed_product|
      product = Product.find_by_shopify_id(parsed_product[:store_id]) || Product.find_by(title: parsed_product[:title]) || Product.new
      product.assign_attributes(
        title: parsed_product[:title],
        franchise: Franchise.find_or_create_by(title: parsed_product[:franchise]),
        shape: parsed_product[:shape] || Product.default_shape
      )
      product.build_base_edition(sku: parsed_product[:sku] || "#{parsed_product[:title].parameterize}-#{rand(1000..9999)}")
      product.save! if product.new_record? || product.changed? || product.base_edition&.new_record? || product.base_edition&.changed?
      product
    end

    # Stub Edition::Shopify::Importer to return unique editions
    allow(Edition::Shopify::Importer).to receive(:import!) do |product, parsed_edition|
      edition_key = "#{product.id}-#{parsed_edition[:id]}"
      created_editions[edition_key] ||= begin
        edition = Edition.find_by_shopify_id(parsed_edition[:id]) || Edition.new(product: product)
        edition.version = Version.find_or_create_by(value: parsed_edition[:title] || "Default")
        product.fill_edition_sku(edition, "shopify-sale-#{parsed_edition[:id] || parsed_edition[:title] || SecureRandom.hex(4)}")
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
        import_order
        expect(Sale.count).to eq(1)
        expect(Customer.count).to eq(1)
        expect(SaleItem.count).to eq(1)
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

        described_class.import!(modified_order_with_new_timestamps)

        sale = Sale.last
        expect(sale.shopify_info.ext_created_at).not_to eq(original_created_at)
      end
    end

    context "when edition already exists" do
      let!(:existing_edition) do
        create(
          :edition,
          product: create(:product, shopify_id: valid_parsed_order[:sale_items].first[:product_store_id]),
          shopify_id: valid_parsed_order[:sale_items].first[:edition_store_id]
        )
      end

      it "uses existing edition" do
        expect { import_order }.not_to change(Edition, :count)
      end
    end

    context "when product sale is corrupted (no product info at all)" do
      let(:parsed_order_corrupted) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first[:edition_store_id] = nil
        order[:sale_items].first[:product_store_id] = nil
        order[:sale_items].first[:edition_title] = nil
        order[:sale_items].first[:full_title] = nil
        order[:sale_items].first[:product] = nil
        order
      end
      let(:importer_corrupted) { described_class.new(parsed_order_corrupted) }

      it "does not create a new edition when edition_title is missing" do
        expect { described_class.import!(parsed_order_corrupted) }.not_to change(Edition, :count)
      end

      it "does not create sale_item when product data is completely missing" do
        expect { described_class.import!(parsed_order_corrupted) }.not_to change(SaleItem, :count)
      end
    end

    context "when sale item has only full_title (no Shopify IDs)" do
      let(:parsed_order_title_only) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          edition_title: "Limited Edition",
          edition_store_id: nil,
          product_store_id: nil,
          product: nil,
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        )
        order
      end

      it "creates product from full_title using Product::Shopify::Parser" do
        expect { described_class.import!(parsed_order_title_only) }.to change(Product, :count).by(1)
        product = Product.last
        expect(product.title).to eq("Princess Leia")
        expect(product.franchise.title).to eq("Star Wars")
      end

      it "creates edition from edition_title" do
        expect { described_class.import!(parsed_order_title_only) }.to change(Edition, :count).by(2)
        expect(Edition.last.version.value).to eq("Limited Edition")
      end

      it "creates sale_item with product and edition" do
        described_class.import!(parsed_order_title_only)
        sale_item = SaleItem.last
        expect(sale_item.product).to be_present
        expect(sale_item.edition).to be_present
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

        expect { described_class.import!(parsed_order_title_only) }.not_to change(Product, :count)
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

        allow(Product::Shopify::Importer).to receive(:import!).and_call_original
        allow(Shopify::PullEditionsJob).to receive(:perform_later)
        allow(Shopify::ImportMediaJob).to receive(:perform_later)

        expect {
          described_class.import!(first_order)
          described_class.import!(second_order)
        }.to change(Product, :count).by(1)
          .and change(Sale, :count).by(2)
          .and change(SaleItem, :count).by(2)

        expect(Sale.order(:id).last(2).map { |sale| sale.sale_items.last.product_id }.uniq.count).to eq(1)
      end

      it "creates sale item without edition when edition_title is blank" do
        parsed_order_without_edition_title = parsed_order_title_only.deep_dup
        parsed_order_without_edition_title[:sale_items].first[:edition_title] = nil
        parsed_order_without_edition_title[:sale_items].first[:store_id] = "gid://shopify/LineItem/title-only-no-edition"
        parsed_order_without_edition_title[:sale][:shopify_id] = "gid://shopify/Order/title-only-no-edition"
        parsed_order_without_edition_title[:store_info][:store_id] = "gid://shopify/Order/title-only-no-edition"

        allow(Product::Shopify::Importer).to receive(:import!).and_call_original
        allow(Shopify::PullEditionsJob).to receive(:perform_later)
        allow(Shopify::ImportMediaJob).to receive(:perform_later)

        expect {
          described_class.import!(parsed_order_without_edition_title)
        }.to change(SaleItem, :count).by(1)
          .and change(Edition, :count).by(1)

        sale_item = SaleItem.last
        expect(sale_item.product).to be_present
        expect(sale_item.edition).to be_nil
      end
    end

    context "when a sale item only has full_title but still includes product_store_id" do
      let(:parsed_order_with_store_id_and_title_only) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          edition_title: "Limited Edition",
          edition_store_id: nil,
          product_store_id: "gid://shopify/Product/title-rebuilt",
          product: nil,
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        )
        order
      end

      before do
        allow(Shopify::PullEditionsJob).to receive(:perform_later)
        allow(Shopify::ImportMediaJob).to receive(:perform_later)
        allow(Shopify::PullProductJob).to receive(:perform_later)
        allow(Product::Shopify::Importer).to receive(:import!).and_call_original
      end

      it "creates a product linked to the known Shopify store id" do
        described_class.import!(parsed_order_with_store_id_and_title_only)

        sale_item = SaleItem.last
        expect(sale_item.product).to be_present
        expect(sale_item.product.shopify_info.store_id).to eq("gid://shopify/Product/title-rebuilt")
      end

      it "enqueues a full Shopify product pull for the missing local product" do
        described_class.import!(parsed_order_with_store_id_and_title_only)

        expect(Shopify::PullProductJob).to have_received(:perform_later).with("gid://shopify/Product/title-rebuilt")
      end
    end

    context "when a Shopify product reference cannot be resolved" do
      let(:parsed_order_with_unresolved_product) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          product_store_id: "gid://shopify/Product/missing-product",
          product: nil,
          full_title: nil
        )
        order
      end

      it "creates the sale item with a placeholder product instead of crashing" do
        expect {
          described_class.import!(parsed_order_with_unresolved_product)
        }.to change(Sale, :count).by(1)
          .and change(SaleItem, :count).by(1)
          .and change(Product, :count).by(1)

        sale_item = SaleItem.last
        expect(sale_item.product.shopify_info.store_id).to eq("gid://shopify/Product/missing-product")
        expect(sale_item.product.title).to include("[BROKEN SHOPIFY PRODUCT]")
      end
    end

    context "when creating new edition with custom title" do
      let(:parsed_order_with_new_edition) do
        order = valid_parsed_order.deep_dup
        # Use existing product with custom edition title (not in product's editions)
        order[:sale_items].first.merge!(
          edition_title: "New Edition",
          edition_store_id: nil,  # No shopify_id, should use create_custom_edition path
          product_store_id: "gid://shopify/Product/999999",
          edition_title_from_product: "Regular",
          product: {
            store_id: "gid://shopify/Product/999999",
            title: "Test Product",
            franchise: "Test Franchise",
            shape: "Statue",
            sku: "test-product-999",
            editions: []
          }
        )
        order
      end

      let(:product) { create(:product, shopify_id: "gid://shopify/Product/999999") }
      let(:edition) { create(:edition, product: product) }

      before do
        allow(Product::Shopify::Importer).to receive(:import!).and_return(product)
        allow(Version).to receive(:find_or_create_by).with(value: "New Edition").and_return(edition.version)
        allow(edition.version).to receive(:value).and_return("New Edition")
        allow_any_instance_of(Edition).to receive(:save!).and_return(true)
        allow_any_instance_of(Version).to receive(:save!).and_return(true)
      end

      it "creates new edition with correct title" do
        expect { described_class.import!(parsed_order_with_new_edition) }.to change(Edition, :count).by(1)
        expect(Edition.last.version.value).to eq("New Edition")
      end
    end

    context "when creating edition with multiple custom attributes" do
      let(:parsed_order_with_complex_edition) do
        order = valid_parsed_order.deep_dup
        # Use existing product with custom edition title (not in product's editions)
        order[:sale_items].first.merge!(
          edition_title: "1:4 | New Edition | Red",
          edition_store_id: nil,  # No shopify_id, should use create_custom_edition path
          product_store_id: "gid://shopify/Product/888888",
          edition_title_from_product: "Regular",
          product: {
            store_id: "gid://shopify/Product/888888",
            title: "Test Product",
            franchise: "Test Franchise",
            shape: "Statue",
            sku: "test-product-888",
            editions: []
          }
        )
        order
      end

      let(:product) { create(:product, shopify_id: "gid://shopify/Product/888888") }
      let(:edition) { create(:edition, product: product) }

      before do
        allow(Product::Shopify::Importer).to receive(:import!).and_return(product)
        allow(Version).to receive(:find_or_create_by).with(value: "1:4 | New Edition | Red").and_return(edition.version)
        allow(edition.version).to receive(:value).and_return("1:4 | New Edition | Red")
        allow_any_instance_of(Edition).to receive(:save!).and_return(true)
        allow_any_instance_of(Version).to receive(:save!).and_return(true)
      end

      it "creates new edition with multiple attributes" do
        expect { described_class.import!(parsed_order_with_complex_edition) }.to change(Edition, :count).by(1)
        expect(Edition.last.version.value).to eq("1:4 | New Edition | Red")
      end
    end

    context "when edition creation fails" do
      let(:parsed_order_with_invalid_edition) do
        order = valid_parsed_order.deep_dup
        order[:sale_items].first.merge!(
          edition_title: "Invalid Edition",
          edition_store_id: "gid://shopify/ProductVariant/12345",
          product_store_id: "gid://shopify/Product/67890",
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
        allow(Product::Shopify::Importer).to receive(:import!).and_return(product)
        allow(Edition::Shopify::Importer).to receive(:import!).and_raise(ActiveRecord::RecordInvalid.new(Edition.new))
      end

      it "rolls back all changes when edition creation fails" do
        expect { described_class.import!(parsed_order_with_invalid_edition) }.to raise_error(Sale::Shopify::Importer::Error)
        expect {
          begin
            described_class.import!(parsed_order_with_invalid_edition)
          rescue
            nil
          end
        }.not_to change(Edition, :count)
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
        create(:product,
          shopify_id: valid_parsed_order[:sale_items].first[:product_store_id],
          title: "Old Product Title")
      end

      it "uses existing product" do
        existing_product # Reference to ensure creation
        expect { import_order }.not_to change(Product, :count)
      end
    end

    context "when sale_item already exists" do
      let!(:existing_sale) { create(:sale, shopify_id: valid_parsed_order[:sale][:store_id]) }
      let!(:existing_sale_item) do
        product = create(:product, shopify_id: valid_parsed_order[:sale_items].first[:product_store_id])
        edition = create(:edition, shopify_id: valid_parsed_order[:sale_items].first[:edition_store_id])

        create(:sale_item,
          shopify_id: valid_parsed_order[:sale_items].first[:store_id],
          price: "500.00",
          qty: 1,
          sale: existing_sale,
          product: product,
          edition: edition)
      end

      it "updates existing sale_item with new data" do
        modified_order = valid_parsed_order.deep_dup
        modified_order[:sale_items].first[:price] = "600.00"

        described_class.import!(modified_order)

        expect { existing_sale_item.reload }.to change(existing_sale_item, :price).to(BigDecimal("600.00"))
      end
    end

    context "when linking purchased products" do
      let(:product) { create(:product) }
      let(:purchase) { create(:purchase, product: product, amount: 3) }
      let!(:purchase_items) { create_list(:purchase_item, 3, purchase: purchase) }
      let!(:existing_sale) do
        sale = create(:sale, status: "pre-ordered")
        sale.update!(shopify_id: valid_parsed_order[:sale][:store_id])
        sale.shopify_info.update(store_id: valid_parsed_order[:store_info][:store_id])
        sale
      end
      let(:sale_item) { create(:sale_item, sale: existing_sale, product: product, qty: 2) }
      # Note: fixture uses :store_id key, importer maps it to shopify_id column
      let(:sale_item_store_id_from_fixture) { valid_parsed_order[:sale_items].first[:store_id] }

      before do
        existing_sale
        sale_item.update(shopify_id: sale_item_store_id_from_fixture)

        # Reset purchase_items_count to 0 so the linkable scope works
        sale_item.update(purchase_items_count: 0)

        # Stub Product::Shopify::Importer to return existing product
        allow(Product::Shopify::Importer).to receive(:import!).and_return(product)
      end

      it "notifies customers about linked products" do
        allow(PurchaseItem).to receive(:notify_order_status!)
        import_order
        expect(PurchaseItem).to have_received(:notify_order_status!).at_least(:once)
      end
    end
  end
end
