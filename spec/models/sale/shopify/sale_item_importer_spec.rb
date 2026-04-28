# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Shopify::SaleItemImporter do
  let(:sale) { create(:sale) }
  let(:product_store_id) { "gid://shopify/Product/123" }
  let(:variant_store_id) { "gid://shopify/ProductVariant/456" }
  let(:product) { create(:product, shopify_id: product_store_id, title: "Existing Product") }
  let(:variant) { create(:variant, product:) }

  describe "#import!" do
    context "when no product data is present" do
      it "returns nil" do
        result = described_class.new(sale, {
          store_id: "gid://shopify/LineItem/1",
          price: "10.00",
          qty: 1
        }).import!

        expect(result).to be_nil
      end
    end

    context "when the sale item references Shopify product and variant ids" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/1",
          price: "10.00",
          qty: 2,
          product_store_id: product_store_id,
          product: {
            store_id: product_store_id,
            title: "Existing Product"
          },
          variant_store_id: variant_store_id,
          variant_title: "Regular"
        }
      end

      before do
        variant.shopify_info.update!(store_id: variant_store_id)
        allow(Product).to receive(:find_by_shopify_id).with(product_store_id).and_return(product)
      end

      it "creates the sale item with the existing product and variant" do
        expect {
          result = described_class.new(sale, parsed_sale_item).import!
          expect(result).to be_persisted
        }.to change(SaleItem, :count).by(1)

        sale_item = SaleItem.last
        expect(sale_item.sale).to eq(sale)
        expect(sale_item.product).to eq(product)
        expect(sale_item.variant).to eq(variant)
        expect(sale_item.shopify_id).to eq("gid://shopify/LineItem/1")
      end
    end

    context "when the sale item includes parsed Shopify product data" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/parsed",
          price: "15.00",
          qty: 1,
          product_store_id: product_store_id,
          product: {
            store_id: product_store_id,
            title: "Parsed Product",
            franchise: "Parsed Franchise",
            shape: "Statue",
            sku: "parsed-sku-1",
            variants: []
          }
        }
      end
      let(:imported_product) { create(:product, title: "Parsed Product") }

      before do
        allow(Product).to receive(:find_by_shopify_id).with(product_store_id).and_return(nil)
        allow(Product::Shopify::Importer).to receive(:import!)
          .with(parsed_sale_item[:product])
          .and_return(imported_product)
        allow(Shopify::PullProductJob).to receive(:perform_later)
      end

      it "imports the product payload before creating the sale item" do
        result = described_class.new(sale, parsed_sale_item).import!

        expect(result).to be_persisted
        expect(result.product).to eq(imported_product)
      end

      it "enqueues a canonical product pull for missing local Shopify products" do
        described_class.new(sale, parsed_sale_item).import!

        expect(Shopify::PullProductJob).to have_received(:perform_later).with(product_store_id)
      end
    end

    context "when only the full title is available" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/2",
          price: "20.00",
          qty: 1,
          variant_title: "Limited Variant",
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        }
      end
      let(:parsed_product) do
        {
          store_id: "gid://shopify/Product/999",
          title: "Princess Leia",
          franchise: "Star Wars",
          shape: "Statue",
          sku: "princess-leia-999",
          variants: []
        }
      end
      let(:imported_product) { create(:product, title: "Princess Leia") }

      before do
        allow(Product::Shopify::Parser).to receive(:parse)
          .with({"title" => parsed_sale_item[:full_title]})
          .and_return(parsed_product)
        allow(Product::Shopify::Importer).to receive(:import!)
          .with(parsed_product)
          .and_return(imported_product)
        allow(Shopify::PullProductJob).to receive(:perform_later)
      end

      it "creates a product and custom variant from the title" do
        expect {
          described_class.new(sale, parsed_sale_item).import!
        }.to change(SaleItem, :count).by(1)
          .and change(Variant, :count).by(1)

        sale_item = SaleItem.last
        expect(sale_item.product).to eq(imported_product)
        expect(sale_item.variant.version.value).to eq("Limited Variant")
      end

      it "does not enqueue a product pull without a Shopify product id" do
        described_class.new(sale, parsed_sale_item).import!

        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end
    end

    context "when product_store_id is present but the product must be rebuilt from full_title" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/2-with-store-id",
          price: "20.00",
          qty: 1,
          product_store_id: "gid://shopify/Product/999",
          variant_title: "Limited Variant",
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        }
      end
      let(:parsed_product) do
        {
          title: "Princess Leia",
          franchise: "Star Wars",
          shape: "Statue",
          sku: "princess-leia-999",
          variants: []
        }
      end
      let(:imported_product) do
        create(:product, shopify_id: "gid://shopify/Product/999", title: "Princess Leia")
      end

      before do
        allow(Product).to receive(:find_by_shopify_id).with("gid://shopify/Product/999").and_return(nil)
        allow(Product::Shopify::Parser).to receive(:parse)
          .with({"title" => parsed_sale_item[:full_title]})
          .and_return(parsed_product)
        allow(Product::Shopify::Importer).to receive(:import!)
          .with(parsed_product.merge(store_id: "gid://shopify/Product/999"))
          .and_return(imported_product)
        allow(Shopify::PullProductJob).to receive(:perform_later)
      end

      it "passes the known Shopify product id into the imported product payload" do
        result = described_class.new(sale, parsed_sale_item).import!

        expect(result).to be_persisted
        expect(result.product).to eq(imported_product)
      end

      it "enqueues a canonical product pull after rebuilding from title" do
        described_class.new(sale, parsed_sale_item).import!

        expect(Shopify::PullProductJob).to have_received(:perform_later).with("gid://shopify/Product/999")
      end
    end

    context "when full_title is present but variant_title is blank" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/no-variant",
          price: "20.00",
          qty: 1,
          variant_title: nil,
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        }
      end
      let(:parsed_product) do
        {
          store_id: "gid://shopify/Product/1000",
          title: "Princess Leia",
          franchise: "Star Wars",
          shape: "Statue",
          sku: "princess-leia-1000",
          variants: []
        }
      end
      let(:imported_product) { create(:product, title: "Princess Leia") }

      before do
        allow(Product::Shopify::Parser).to receive(:parse)
          .with({"title" => parsed_sale_item[:full_title]})
          .and_return(parsed_product)
        allow(Product::Shopify::Importer).to receive(:import!)
          .with(parsed_product)
          .and_return(imported_product)
      end

      it "creates sale item with product and no variant" do
        expect {
          described_class.new(sale, parsed_sale_item).import!
        }.to change(SaleItem, :count).by(1)
          .and change(Variant, :count).by(0) # rubocop:todo RSpec/ChangeByZero

        sale_item = SaleItem.last
        expect(sale_item.product).to eq(imported_product)
        expect(sale_item.variant).to be_nil
      end
    end

    context "when full_title is present but variant_title sanitizes to blank" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/no-variant-sanitized",
          price: "20.00",
          qty: 1,
          variant_title: "\u00A0",
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        }
      end
      let(:parsed_product) do
        {
          store_id: "gid://shopify/Product/1001",
          title: "Princess Leia",
          franchise: "Star Wars",
          shape: "Statue",
          sku: "princess-leia-1001",
          variants: []
        }
      end
      let(:imported_product) { create(:product, title: "Princess Leia") }

      before do
        allow(Product::Shopify::Parser).to receive(:parse)
          .with({"title" => parsed_sale_item[:full_title]})
          .and_return(parsed_product)
        allow(Product::Shopify::Importer).to receive(:import!)
          .with(parsed_product)
          .and_return(imported_product)
      end

      it "creates sale item with product and no variant" do
        expect {
          described_class.new(sale, parsed_sale_item).import!
        }.to change(SaleItem, :count).by(1)
          .and change(Variant, :count).by(0) # rubocop:todo RSpec/ChangeByZero

        sale_item = SaleItem.last
        expect(sale_item.product).to eq(imported_product)
        expect(sale_item.variant).to be_nil
      end
    end

    context "when Shopify sends the default variant title" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/default-title",
          price: "20.00",
          qty: 1,
          variant_title: "Default Title",
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        }
      end
      let(:parsed_product) do
        {
          store_id: "gid://shopify/Product/1002",
          title: "Princess Leia",
          franchise: "Star Wars",
          shape: "Statue",
          sku: "princess-leia-1002",
          variants: []
        }
      end
      let(:imported_product) { create(:product, title: "Princess Leia") }

      before do
        allow(Product::Shopify::Parser).to receive(:parse)
          .with({"title" => parsed_sale_item[:full_title]})
          .and_return(parsed_product)
        allow(Product::Shopify::Importer).to receive(:import!)
          .with(parsed_product)
          .and_return(imported_product)
      end

      it "creates sale item with the base model variant" do
        expect {
          described_class.new(sale, parsed_sale_item).import!
        }.to change(SaleItem, :count).by(1)
          .and change(Variant, :count).by(0) # rubocop:todo RSpec/ChangeByZero

        sale_item = SaleItem.last
        expect(sale_item.product).to eq(imported_product)
        expect(sale_item.variant).to be_present
        expect(sale_item.variant.title).to eq("Base Model")
      end
    end

    context "when a Shopify product reference cannot be resolved" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/missing",
          price: "30.00",
          qty: 1,
          product_store_id: product_store_id,
          product: nil
        }
      end

      before do
        allow(Shopify::PullProductJob).to receive(:perform_later)
      end

      it "creates and uses a placeholder product instead of raising" do
        expect {
          result = described_class.new(sale, parsed_sale_item).import!
          expect(result).to be_persisted
          expect(result.product.shopify_info.store_id).to eq(product_store_id)
          expect(result.product.title).to include("[BROKEN SHOPIFY PRODUCT]")
        }.to change(SaleItem, :count).by(1)
          .and change(Product, :count).by(1)
      end

      it "enqueues a background pull for the missing Shopify product" do
        described_class.new(sale, parsed_sale_item).import!

        expect(Shopify::PullProductJob).to have_received(:perform_later).with(product_store_id)
      end
    end
  end
end
