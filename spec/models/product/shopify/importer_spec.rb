# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Importer do
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
        tags: [],
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
        .and change(Brand, :count).by(1)
        .and change(Size, :count).by(1)

      product = Product.last
      expect(product.shopify_info.store_id).to eq("gid://shopify/Product/12345")
      expect(product.shopify_info.slug).to eq("stellar-blade-eve-statue")
      expect(product.title).to eq("Eve")
      expect(product.franchise.title).to eq("Stellar Blade")
      expect(product.shape).to eq("Statue")
      expect(product.brands.first.title).to eq("Light and Dust Studio")
      expect(product.sizes.first.value).to eq("1:4")
    end

    it "enqueues sync jobs for editions and media" do # rubocop:todo RSpec/MultipleExpectations
      allow(Shopify::PullEditionsJob).to receive(:perform_later)
      allow(Shopify::ImportMediaJob).to receive(:perform_later)

      product = described_class.import!(parsed_product)

      expect(Shopify::PullEditionsJob).to have_received(:perform_later).with(product, parsed_product[:editions])
      expect(Shopify::ImportMediaJob).to have_received(:perform_later).with(product, parsed_product[:media])
    end

    it "generates correct full title" do
      product = described_class.import!(parsed_product)
      expect(product.full_title).to eq("Stellar Blade — Eve | Light and Dust Studio")
    end

    it "does not route a variant SKU to the base edition for multi-variant products" do
      product = described_class.import!(parsed_product.merge(
        sku: "TEST-SKU-001",
        editions: [
          {store_id: "gid://shopify/ProductVariant/67890", is_single_variant: false},
          {store_id: "gid://shopify/ProductVariant/67891", is_single_variant: false}
        ]
      ))

      expect(product.base_edition.sku).not_to eq("TEST-SKU-001")
    end

    it "routes provided SKU to the base edition for single-variant products" do
      product = described_class.import!(parsed_product.merge(
        editions: [
          {store_id: "gid://shopify/ProductVariant/67890", is_single_variant: true}
        ]
      ))

      expect(product.base_edition.sku).to eq("TEST-SKU-001")
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
      expect(product.shopify_info.ext_created_at).to eq(Time.zone.parse(parsed_product[:store_info][:ext_created_at]))
      expect(product.shopify_info.ext_updated_at).to eq(Time.zone.parse(parsed_product[:store_info][:ext_updated_at]))
    end

    it "sets pull_time on StoreInfo" do
      product = described_class.import!(parsed_product)
      product.reload
      expect(product.shopify_info.pull_time).to be_within(1.second).of(Time.zone.now)
    end

    it "saves tags to StoreInfo" do
      parsed_with_tags = parsed_product.merge(tags: ["statue", "premium", "exclusive"])
      product = described_class.import!(parsed_with_tags)
      product.reload

      expect(product.shopify_info.tag_list).to eq(["statue", "premium", "exclusive"])
    end

    it "saves empty tag list when no tags are provided" do
      parsed_with_no_tags = parsed_product.merge(tags: [])
      product = described_class.import!(parsed_with_no_tags)
      product.reload

      expect(product.shopify_info.tag_list).to eq([])
    end

    it "returns the product" do # rubocop:todo RSpec/MultipleExpectations
      result = described_class.import!(parsed_product)
      expect(result).to be_a(Product)
      expect(result).to be_persisted
    end

    it "raises when parsed payload is blank" do
      expect {
        described_class.import!(nil)
      }.to raise_error(ArgumentError, "Parsed payload cannot be blank")
    end

    context "with description" do
      let(:parsed_product_with_description) do
        parsed_product.merge(
          description: "<p>This is a <strong>premium</strong> collectible statue.</p>"
        )
      end

      it "saves description to product" do
        product = described_class.import!(parsed_product_with_description)
        product.reload

        expect(product.description.body.to_html.strip).to eq("<p>This is a <strong>premium</strong> collectible statue.</p>")
      end
    end

    context "with description containing nested p tags inside li" do
      let(:parsed_product_with_list) do
        parsed_product.merge(
          description: "<ul><li><p>Item 1</p></li><li><p>Item 2</p></li></ul>"
        )
      end

      it "normalizes HTML by unwrapping p tags inside li", :aggregate_failures do
        product = described_class.import!(parsed_product_with_list)
        product.reload

        html = product.description.body.to_html
        expect(html).to include("<li>Item 1</li>")
        expect(html).to include("<li>Item 2</li>")
        expect(html).not_to include("<li><p>")
      end
    end

    context "with description containing nested div tags inside li" do
      let(:parsed_product_with_div_list) do
        parsed_product.merge(
          description: "<ul><li><div>Item A</div></li><li><div>Item B</div></li></ul>"
        )
      end

      it "normalizes HTML by unwrapping div tags inside li", :aggregate_failures do
        product = described_class.import!(parsed_product_with_div_list)
        product.reload

        html = product.description.body.to_html
        expect(html).to include("<li>Item A</li>")
        expect(html).to include("<li>Item B</li>")
        expect(html).not_to include("<li><div>")
      end
    end

    context "with nil description" do
      let(:parsed_product_nil_description) { parsed_product.merge(description: nil) }

      it "handles nil description gracefully" do
        product = described_class.import!(parsed_product_nil_description)
        product.reload

        expect(product.description.body).to be_blank
      end
    end

    context "without description" do
      let(:parsed_product_no_description) { parsed_product.except(:description) }

      it "leaves description blank" do
        product = described_class.import!(parsed_product_no_description)
        product.reload

        expect(product.description.body).to be_blank
      end
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
        expect(existing_product.shopify_info.ext_created_at).to eq(Time.zone.parse(parsed_product[:store_info][:ext_created_at]))
        expect(existing_product.shopify_info.ext_updated_at).to eq(Time.zone.parse(parsed_product[:store_info][:ext_updated_at]))
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

    context "when product exists without Shopify or Woo linkage and matches parsed identity" do
      let!(:existing_product) do
        create(:product,
          title: "Eve",
          franchise: create(:franchise, title: "Stellar Blade"),
          shape: "Statue").tap do |product|
          product.store_infos.destroy_all
          product.update_columns(shopify_id: nil, woo_id: nil)
          product.reload
          product.base_edition.update!(sku: "storeless-eve-sku")
          product.brands << create(:brand, title: "Light and Dust Studio")
          product.sizes << create(:size, value: "1:4")
        end
      end

      let(:parsed_product_without_linkage) do
        parsed_product.merge(
          store_id: nil,
          store_link: nil,
          media: [],
          editions: []
        )
      end

      it "reuses the storeless product instead of creating a duplicate" do
        expect { described_class.import!(parsed_product_without_linkage) }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.title).to eq("Eve")
        expect(existing_product.base_edition.sku).to eq("storeless-eve-sku")
      end
    end

    context "when product already exists with Woo linkage and matching identity" do
      let!(:existing_product) do
        create(:product,
          title: "Eve",
          franchise: Franchise.find_or_create_by!(title: "Stellar Blade"),
          shape: "Statue").tap do |product|
          product.store_infos.destroy_all
          product.update_columns(shopify_id: nil, woo_id: "woo-product-123")
          product.reload
          product.base_edition.update!(sku: "woo-linked-eve-sku")
          product.store_infos.create!(store_name: :woo, store_id: "woo-product-123", pull_time: Time.zone.now)
          product.brands << Brand.find_or_create_by!(title: "Light and Dust Studio")
          product.sizes << Size.find_or_create_by!(value: "1:4")
        end
      end

      it "reuses the Woo-linked product and attaches Shopify linkage" do
        expect { described_class.import!(parsed_product) }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.shopify_info.store_id).to eq("gid://shopify/Product/12345")
        expect(existing_product.base_edition.sku).to eq("woo-linked-eve-sku")
      end
    end

    context "when a matching product is already linked to another Shopify product" do
      let!(:existing_product) do
        create(:product,
          shopify_id: "gid://shopify/Product/already-linked",
          title: "Eve",
          franchise: Franchise.find_or_create_by!(title: "Stellar Blade"),
          shape: "Statue").tap do |product|
          product.base_edition.update!(sku: "already-linked-sku")
          product.brands << Brand.find_or_create_by!(title: "Light and Dust Studio")
          product.sizes << Size.find_or_create_by!(value: "1:4")
        end
      end

      it "creates a new product instead of reusing the differently linked Shopify product" do
        expect { described_class.import!(parsed_product) }.to change(Product, :count).by(1)

        expect(Product.find_by_shopify_id("gid://shopify/Product/12345")).not_to eq(existing_product)
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
          .and change(Brand, :count).by(0) # rubocop:todo RSpec/ChangeByZero
          .and change(Size, :count).by(0) # rubocop:todo RSpec/ChangeByZero
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

      it "does not enqueue ImportMediaJob" do
        allow(Shopify::ImportMediaJob).to receive(:perform_later)

        described_class.import!(parsed_product_no_media)

        expect(Shopify::ImportMediaJob).not_to have_received(:perform_later)
      end
    end

    context "when no shopify_id is provided" do
      let(:parsed_product_no_id) { parsed_product.except(:store_id) }

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

    it "assigns the parsed shape directly to the product" do
      product = described_class.import!(parsed_product.merge(shape: "Bust"))

      expect(product.shape).to eq("Bust")
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
        sku: "test-sku-123",
        tags: []
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
