require "rails_helper"

RSpec.describe Shopify::ProductCreator do
  describe "#update_or_create" do
    let(:parsed_product) do
      {
        shopify_id: "gid://shopify/Product/12345",
        store_link: "stellar-blade-eve-statue",
        title: "Eve",
        franchise: "Stellar Blade",
        size: "1:4",
        shape: "Statue",
        brand: "Light and Dust Studio",
        images: [{"src" => "https://example.com/image1.jpg"}],
        variations: [{id: "gid://shopify/ProductVariant/67890"}]
      }
    end

    let(:creator) { described_class.new(parsed_product: parsed_product) }

    context "when product doesn't exist" do
      it "creates a new product with correct attributes" do
        expect { creator.update_or_create! }.to change(Product, :count).by(1)
          .and change(Franchise, :count).by(1)
          .and change(Shape, :count).by(1)
          .and change(Brand, :count).by(1)
          .and change(Size, :count).by(1)

        product = Product.last
        expect(product.shopify_id).to eq("gid://shopify/Product/12345")
        expect(product.store_link).to eq("stellar-blade-eve-statue")
        expect(product.title).to eq("Eve")
        expect(product.franchise.title).to eq("Stellar Blade")
        expect(product.shape.title).to eq("Statue")
        expect(product.brands.first.title).to eq("Light and Dust Studio")
        expect(product.sizes.first.value).to eq("1:4")
      end

      it "enqueues sync jobs for variations and images" do
        allow(Shopify::SyncVariationsJob).to receive(:perform_later)
        allow(Shopify::SyncImagesJob).to receive(:perform_later)

        creator.update_or_create!

        expect(Shopify::SyncVariationsJob).to have_received(:perform_later)
        expect(Shopify::SyncImagesJob).to have_received(:perform_later)
      end
    end

    context "when product already exists" do
      let!(:existing_product) do
        create(:product,
          shopify_id: "gid://shopify/Product/12345",
          title: "Old Title")
      end

      it "updates the existing product" do
        expect { creator.update_or_create! }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.title).to eq("Eve")
        expect(existing_product.store_link).to eq("stellar-blade-eve-statue")
      end
    end

    it "returns nil if parsed_product is blank" do
      creator = described_class.new(parsed_product: {})
      expect(creator.update_or_create!).to be_nil
    end
  end

  describe "#update_or_create_by_title" do
    let(:creator_by_title) { described_class.new(parsed_title: "Stellar Blade - Eve | 1:4 Resin Statue | Light and Dust Studio") }

    before do
      allow_any_instance_of(Shopify::ProductParser).to receive(:parse_product_title).and_return(
        ["Eve", "Stellar Blade", "1:4", "Statue", "Light and Dust Studio"]
      )
    end

    it "creates a product based on parsed title" do
      expect { creator_by_title.update_or_create_by_title }.to change(Product, :count).by(1)
        .and change(Franchise, :count).by(1)
        .and change(Shape, :count).by(1)
        .and change(Brand, :count).by(1)
        .and change(Size, :count).by(1)

      product = Product.last
      expect(product.title).to eq("Eve")
      expect(product.franchise.title).to eq("Stellar Blade")
      expect(product.shape.title).to eq("Statue")
      expect(product.brands.first.title).to eq("Light and Dust Studio")
      expect(product.sizes.first.value).to eq("1:4")
    end

    it "finds existing product if it matches core attributes" do
      existing_product = create(:product,
        title: "Eve",
        franchise: create(:franchise, title: "Stellar Blade"),
        shape: create(:shape, title: "Statue"))

      result = creator_by_title.update_or_create_by_title

      expect(result).to eq(existing_product)
      expect(result.sizes.first.value).to eq("1:4")
    end
  end
end
