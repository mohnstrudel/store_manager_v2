# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Shopify::SaleItemImporter do
  let(:sale) { create(:sale) }
  let(:product_store_id) { "gid://shopify/Product/123" }
  let(:variant_store_id) { "gid://shopify/ProductVariant/456" }
  let(:product) { create(:product, :synced, shopify_id: product_store_id, title: "Existing Product") }
  let(:variant) { create(:variant, :synced, product:) }

  describe "#import" do
    context "when no product data is present" do
      it "returns nil" do
        result = described_class.new(sale, {
          store_id: "gid://shopify/LineItem/1",
          price: "10.00",
          qty: 1
        }).import

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
          result = described_class.new(sale, parsed_sale_item).import
          expect(result).to be_persisted
        }.to change(SaleItem, :count).by(1)

        sale_item = SaleItem.last
        expect(sale_item.sale).to eq(sale)
        expect(sale_item.product).to eq(product)
        expect(sale_item.variant).to eq(variant)
        expect(sale_item.shopify_id).to eq("gid://shopify/LineItem/1")
      end
    end

    context "when the product built from the line's title does not import" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/invalid-product",
          price: "15.00",
          qty: 1,
          product_store_id: product_store_id,
          full_title: "Star Wars - Princess Leia | 1:4 | Resin Statue | by von xionart"
        }
      end

      before do
        allow(Product::Shopify::Importer).to receive(:import)
          .and_raise(Product::Shopify::Importer::Error, "Failed to process Product: Title can't be blank")
      end

      it "fails the sale import with the product's errors and the sale item's context" do
        expect { described_class.new(sale, parsed_sale_item).import }
          .to raise_error(Sale::Shopify::Importer::Error) { |error|
            expect(error.message).to start_with("Failed to process Product: Title can't be blank\nsale_store_id: ")
            expect(error.message).to include("sale_item_store_id: gid://shopify/LineItem/invalid-product", "product_store_id: #{product_store_id}")
          }
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
        allow(Product::Shopify::Importer).to receive(:import)
          .with(parsed_product)
          .and_return(imported_product)
      end

      it "creates a product and custom variant from the title" do
        expect {
          described_class.new(sale, parsed_sale_item).import
        }.to change(SaleItem, :count).by(1)
          .and change(Variant, :count).by(1)

        sale_item = SaleItem.last
        expect(sale_item.product).to eq(imported_product)
        expect(sale_item.variant.version.value).to eq("Limited Variant")
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
        create(:product, :synced, shopify_id: "gid://shopify/Product/999", title: "Princess Leia")
      end

      before do
        allow(Product).to receive(:find_by_shopify_id).with("gid://shopify/Product/999").and_return(nil)
        allow(Product::Shopify::Parser).to receive(:parse)
          .with({"title" => parsed_sale_item[:full_title]})
          .and_return(parsed_product)
        allow(Product::Shopify::Importer).to receive(:import)
          .with(parsed_product.merge(store_id: "gid://shopify/Product/999"))
          .and_return(imported_product)
        allow(Shopify::PullProductJob).to receive(:perform_later)
      end

      it "passes the known Shopify product id into the imported product payload" do
        result = described_class.new(sale, parsed_sale_item).import

        expect(result).to be_persisted
        expect(result.product).to eq(imported_product)
      end

      it "enqueues no product pull after rebuilding from title" do
        described_class.new(sale, parsed_sale_item).import

        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
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
        allow(Product::Shopify::Importer).to receive(:import)
          .with(parsed_product)
          .and_return(imported_product)
      end

      it "creates a sale item with the Product Base Variant" do
        expect {
          described_class.new(sale, parsed_sale_item).import
        }.to change(SaleItem, :count).by(1)
          .and change(Variant, :count).by(0) # rubocop:todo RSpec/ChangeByZero

        sale_item = SaleItem.last
        expect(sale_item.product).to eq(imported_product)
        expect(sale_item.variant).to eq(imported_product.base_variant)
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
        allow(Product::Shopify::Importer).to receive(:import)
          .with(parsed_product)
          .and_return(imported_product)
      end

      it "creates a sale item with the Product Base Variant" do
        expect {
          described_class.new(sale, parsed_sale_item).import
        }.to change(SaleItem, :count).by(1)
          .and change(Variant, :count).by(0) # rubocop:todo RSpec/ChangeByZero

        sale_item = SaleItem.last
        expect(sale_item.product).to eq(imported_product)
        expect(sale_item.variant).to eq(imported_product.base_variant)
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
        allow(Product::Shopify::Importer).to receive(:import)
          .with(parsed_product)
          .and_return(imported_product)
      end

      it "creates sale item with the base model variant" do
        expect {
          described_class.new(sale, parsed_sale_item).import
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
          result = described_class.new(sale, parsed_sale_item).import
          expect(result).to be_persisted
          expect(result.product.shopify_info.store_id).to eq(product_store_id)
          expect(result.product.title).to include("[BROKEN SHOPIFY PRODUCT]")
        }.to change(SaleItem, :count).by(1)
          .and change(Product, :count).by(1)
      end

      it "enqueues no product pull for the missing Shopify product" do
        described_class.new(sale, parsed_sale_item).import

        expect(Shopify::PullProductJob).not_to have_received(:perform_later)
      end
    end

    context "when the Shopify variant resolves to a deactivated variant" do
      let(:deactivated_variant) { product.variants.base_models.first }
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/deactivated",
          price: "10.00",
          qty: 1,
          product_store_id: product_store_id,
          variant_store_id: variant_store_id,
          variant_title: "Default Title"
        }
      end

      before do
        create(:variant, :with_version, product:)
        deactivated_variant.upsert_shopify_info(store_id: variant_store_id)
      end

      it "saves the line on that variant" do
        expect(deactivated_variant).to be_deactivated

        result = described_class.new(sale, parsed_sale_item).import

        expect(result).to be_persisted
        expect(result.variant).to eq(deactivated_variant)
      end
    end

    context "when the line resolves to a deactivated variant by its title" do
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/by-title",
          price: "10.00",
          qty: 1,
          product_store_id: product_store_id,
          variant_title: "Gold"
        }
      end

      before do
        create(:variant, :with_version, product:)
        create(:variant, product:, version: create(:version, value: "Gold")).deactivate
      end

      it "still fails variant assignability validation" do
        expect { described_class.new(sale, parsed_sale_item).import }
          .to raise_error(Sale::Shopify::Importer::Error, /Variant is not assignable/)
      end
    end

    context "when the resolved product is flagged non_catalog (a Seal installment placeholder)" do
      let(:placeholder_product) { create(:product, :synced, shopify_id: product_store_id, non_catalog: true, title: "Unattributed Installment Payment") }
      let(:parsed_sale_item) do
        {
          store_id: "gid://shopify/LineItem/installment-1",
          price: "130.00",
          qty: 1,
          product_store_id: product_store_id,
          variant_store_id: variant_store_id
        }
      end

      before do
        allow(Product).to receive(:find_by_shopify_id).with(product_store_id).and_return(placeholder_product)
      end

      it "imports the sale item on the placeholder product without redirecting or linking an origin item" do
        real_product = create(:product, title: "Astarion")
        origin_sale = create(:sale, customer: sale.customer)
        create(:sale_item, sale: origin_sale, product: real_product)

        result = described_class.new(sale, parsed_sale_item).import

        expect(result.product).to eq(placeholder_product)
        expect(result.origin_sale_item).to be_nil
      end
    end
  end
end
