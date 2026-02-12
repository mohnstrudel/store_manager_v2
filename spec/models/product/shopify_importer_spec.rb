# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::ShopifyImporter do
  describe ".import!" do
    let(:parsed_product) do
      {
        store_id: "gid://shopify/Product/12345",
        store_link: "stellar-blade-eve-statue",
        title: "Eve",
        franchise: "Stellar Blade",
        size: "1:4",
        shape: "Statue",
        brand: "Light and Dust Studio",
        sku: "TEST-SKU-001",
        store_info: {
          ext_created_at: 1.day.ago.iso8601,
          ext_updated_at: 1.hour.ago.iso8601
        },
        media: [{id: "gid://shopify/MediaImage/1", url: "https://example.com/image.jpg"}],
        editions: [{id: "gid://shopify/ProductVariant/67890"}]
      }
    end

    it "creates a new product with correct attributes" do # rubocop:todo RSpec/MultipleExpectations
      expect { described_class.import!(parsed_product) }.to change(Product, :count).by(1)
        .and change(Franchise, :count).by(1)
        .and change(Shape, :count).by(1)
        .and change(Brand, :count).by(1)
        .and change(Size, :count).by(1)

      product = Product.last
      expect(product.shopify_info.store_id).to eq("gid://shopify/Product/12345")
      expect(product.shopify_info.slug).to eq("stellar-blade-eve-statue")
      expect(product.title).to eq("Eve")
      expect(product.franchise.title).to eq("Stellar Blade")
      expect(product.shape.title).to eq("Statue")
      expect(product.brands.first.title).to eq("Light and Dust Studio")
      expect(product.sizes.first.value).to eq("1:4")
    end

    it "enqueues sync jobs for editions and media" do # rubocop:todo RSpec/MultipleExpectations
      allow(Shopify::PullEditionsJob).to receive(:perform_later)
      allow(Shopify::PullMediaJob).to receive(:perform_later)

      product = described_class.import!(parsed_product)

      expect(Shopify::PullEditionsJob).to have_received(:perform_later).with(product, parsed_product[:editions])
      expect(Shopify::PullMediaJob).to have_received(:perform_later).with(product.id, parsed_product[:media])
    end

    it "generates correct full title" do
      product = described_class.import!(parsed_product)
      expect(product.full_title).to eq("Stellar Blade — Eve | Light and Dust Studio")
    end

    it "uses provided SKU" do
      product = described_class.import!(parsed_product)
      expect(product.sku).to eq("TEST-SKU-001")
    end

    it "saves Shopify ID to StoreInfo" do # rubocop:todo RSpec/MultipleExpectations
      product = described_class.import!(parsed_product)
      product.reload # Clear association cache to see newly created store_info
      expect(product.shopify_info).to be_present
      expect(product.shopify_info.store_id).to eq("gid://shopify/Product/12345")
      expect(product.shopify_info.shopify?).to be true
    end

    it "saves ext_created_at and ext_updated_at to StoreInfo" do # rubocop:todo RSpec/MultipleExpectations
      product = described_class.import!(parsed_product)
      product.reload
      expect(product.shopify_info.ext_created_at).to be_within(2.seconds).of(1.day.ago)
      expect(product.shopify_info.ext_updated_at).to be_within(2.seconds).of(1.hour.ago)
    end

    it "sets pull_time on StoreInfo" do
      product = described_class.import!(parsed_product)
      product.reload
      expect(product.shopify_info.pull_time).to be_within(1.second).of(Time.zone.now)
    end

    it "returns the product" do # rubocop:todo RSpec/MultipleExpectations
      result = described_class.import!(parsed_product)
      expect(result).to be_a(Product)
      expect(result).to be_persisted
    end

    context "when product already exists" do
      let!(:existing_product) do
        create(:product,
          shopify_id: "gid://shopify/Product/12345",
          title: "Old Title")
      end

      it "updates the existing product" do # rubocop:todo RSpec/MultipleExpectations
        expect { described_class.import!(parsed_product) }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.title).to eq("Eve")
        expect(existing_product.shopify_info.slug).to eq("stellar-blade-eve-statue")
      end

      it "updates ext_created_at and ext_updated_at" do # rubocop:todo RSpec/MultipleExpectations
        original_created_at = existing_product.shopify_info.ext_created_at
        original_updated_at = existing_product.shopify_info.ext_updated_at

        described_class.import!(parsed_product)

        existing_product.shopify_info.reload
        expect(existing_product.shopify_info.ext_created_at).not_to eq(original_created_at)
        expect(existing_product.shopify_info.ext_updated_at).not_to eq(original_updated_at)
        expect(existing_product.shopify_info.ext_created_at).to be_within(1.second).of(1.day.ago)
        expect(existing_product.shopify_info.ext_updated_at).to be_within(1.second).of(1.hour.ago)
      end

      it "returns the existing product" do
        result = described_class.import!(parsed_product)
        expect(result).to eq(existing_product)
      end
    end

    context "when product has StoreInfo with slug but no store_id" do
      let!(:existing_product) do
        create(:product).tap do |p|
          p.shopify_info.update(store_id: nil, slug: "stellar-blade-eve-statue")
        end
      end

      it "finds the existing product by its StoreInfo slug" do
        expect { described_class.import!(parsed_product) }.not_to change(Product, :count)
      end

      it "updates the store_id in the existing StoreInfo" do # rubocop:todo RSpec/MultipleExpectations
        expect(existing_product.shopify_info.store_id).to be_nil

        expect { described_class.import!(parsed_product) }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.shopify_info.store_id).to eq("gid://shopify/Product/12345")
      end
    end

    context "with nil or empty relation values" do
      let(:parsed_product_with_nil_values) do
        parsed_product.merge(
          brand: nil,
          size: nil
        )
      end

      it "handles nil relation values gracefully" do
        expect { described_class.import!(parsed_product_with_nil_values) }.not_to raise_error
      end

      it "does not create Brand or Size when nil" do # rubocop:todo RSpec/MultipleExpectations
        expect { described_class.import!(parsed_product_with_nil_values) }
          .to change(Product, :count).by(1)
          .and change(Franchise, :count).by(1)
          .and change(Shape, :count).by(1)
          .and change(Brand, :count).by(0) # rubocop:todo RSpec/ChangeByZero
          .and change(Size, :count).by(0) # rubocop:todo RSpec/ChangeByZero
      end
    end

    context "when generating full title from parsed data" do
      it "builds full title with brand" do
        product = described_class.import!(parsed_product)
        expect(product.full_title).to eq("Stellar Blade — Eve | Light and Dust Studio")
      end

      it "builds full title without brand" do
        parsed_product_without_brand = parsed_product.merge(brand: nil)
        product = described_class.import!(parsed_product_without_brand)
        expect(product.full_title).to eq("Stellar Blade — Eve")
      end

      it "builds full title when title equals franchise" do
        parsed_product_same_title = parsed_product.merge(
          title: "Stellar Blade",
          franchise: "Stellar Blade",
          brand: "Light and Dust Studio"
        )
        product = described_class.import!(parsed_product_same_title)
        expect(product.full_title).to eq("Stellar Blade | Light and Dust Studio")
      end

      it "builds full title when title equals franchise without brand" do
        parsed_product_same_title = parsed_product.merge(
          title: "Stellar Blade",
          franchise: "Stellar Blade",
          brand: nil
        )
        product = described_class.import!(parsed_product_same_title)
        expect(product.full_title).to eq("Stellar Blade")
      end
    end

    context "when no editions are provided" do
      let(:parsed_product_no_editions) { parsed_product.merge(editions: nil) }

      it "does not enqueue PullEditionsJob" do
        allow(Shopify::PullEditionsJob).to receive(:perform_later)

        described_class.import!(parsed_product_no_editions)

        expect(Shopify::PullEditionsJob).not_to have_received(:perform_later)
      end
    end

    context "when no media are provided" do
      let(:parsed_product_no_media) { parsed_product.merge(media: nil) }

      it "does not enqueue PullMediaJob" do
        allow(Shopify::PullMediaJob).to receive(:perform_later)

        described_class.import!(parsed_product_no_media)

        expect(Shopify::PullMediaJob).not_to have_received(:perform_later)
      end
    end

    context "when no shopify_id is provided" do
      let(:parsed_product_no_id) { parsed_product.except(:shopify_id) }

      it "creates a new product without store_info" do # rubocop:todo RSpec/MultipleExpectations
        product = described_class.import!(parsed_product_no_id)
        expect(product).to be_persisted
        expect(product.shopify_info).to be_nil
      end
    end

    context "when brand already exists" do
      let!(:existing_brand) { create(:brand, title: "Light and Dust Studio") }

      it "uses existing brand instead of creating new one" do # rubocop:todo RSpec/MultipleExpectations
        expect { described_class.import!(parsed_product) }
          .to change(Product, :count).by(1)
          .and change(Brand, :count).by(0) # rubocop:todo RSpec/ChangeByZero

        expect(Product.last.brands).to include(existing_brand)
      end
    end

    context "when size already exists" do
      let!(:existing_size) { create(:size, value: "1:4") }

      it "uses existing size instead of creating new one" do # rubocop:todo RSpec/MultipleExpectations
        expect { described_class.import!(parsed_product) }
          .to change(Product, :count).by(1)
          .and change(Size, :count).by(0) # rubocop:todo RSpec/ChangeByZero

        expect(Product.last.sizes).to include(existing_size)
      end
    end

    context "when franchise already exists" do
      let!(:existing_franchise) { create(:franchise, title: "Stellar Blade") }

      it "uses existing franchise instead of creating new one" do # rubocop:todo RSpec/MultipleExpectations
        expect { described_class.import!(parsed_product) }
          .to change(Product, :count).by(1)
          .and change(Franchise, :count).by(0) # rubocop:todo RSpec/ChangeByZero

        expect(Product.last.franchise).to eq(existing_franchise)
      end
    end

    context "when shape already exists" do
      let!(:existing_shape) { create(:shape, title: "Statue") }

      it "uses existing shape instead of creating new one" do # rubocop:todo RSpec/MultipleExpectations
        expect { described_class.import!(parsed_product) }
          .to change(Product, :count).by(1)
          .and change(Shape, :count).by(0) # rubocop:todo RSpec/ChangeByZero

        expect(Product.last.shape).to eq(existing_shape)
      end
    end
  end

  describe "#initialize" do
    let(:parsed_payload) { {store_id: "123", title: "Test"} }

    it "stores the parsed payload" do
      importer = described_class.new(parsed_payload)
      expect(importer.instance_variable_get(:@parsed)).to eq(parsed_payload)
    end
  end

  describe "#update_or_create!" do
    let(:parsed_product) do
      {
        store_id: "gid://shopify/Product/12345",
        store_link: "test-product",
        title: "Test Product",
        franchise: "Test Franchise",
        shape: "Statue",
        sku: "test-sku-123"
      }
    end

    let(:importer) { described_class.new(parsed_product) }

    it "creates a new product" do
      expect { importer.update_or_create! }.to change(Product, :count).by(1)
    end

    it "returns the product" do
      result = importer.update_or_create!
      expect(result).to be_a(Product)
    end

    context "when validations fail" do
      before do
        allow_any_instance_of(Product).to receive(:save!).and_raise( # rubocop:todo RSpec/AnyInstance
          ActiveRecord::RecordInvalid.new(Product.new)
        )
      end

      it "raises the error" do
        expect { importer.update_or_create! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
