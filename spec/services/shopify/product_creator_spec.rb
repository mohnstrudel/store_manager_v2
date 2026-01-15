# frozen_string_literal: true

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
        editions: [{id: "gid://shopify/ProductVariant/67890"}]
      }
    end

    let(:creator) { described_class.new(parsed_item: parsed_product) }

    context "when product doesn't exist" do
      it "creates a new product with correct attributes" do # rubocop:todo RSpec/MultipleExpectations
        expect { creator.update_or_create! }.to change(Product, :count).by(1)
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

      it "enqueues sync jobs for editions and images" do # rubocop:todo RSpec/MultipleExpectations
        allow(Shopify::PullEditionsJob).to receive(:perform_later)
        allow(Shopify::PullMediaJob).to receive(:perform_later)

        creator.update_or_create!

        expect(Shopify::PullEditionsJob).to have_received(:perform_later)
        expect(Shopify::PullMediaJob).to have_received(:perform_later)
      end

      it "generates correct full title" do
        creator.update_or_create!
        product = Product.last
        expect(product.full_title).to eq(Product.generate_full_title(product))
      end

      it "generates SKU from full_title" do
        creator.update_or_create!
        product = Product.last
        expect(product.sku).to be_present
        expect(product.sku).to match(/^stellar-blade-eve-light-and-dust-studio-[a-z0-9]{8}$/)
      end

      it "saves Shopify ID to StoreInfo" do
        creator.update_or_create!
        product = Product.last
        expect(product.shopify_info).to be_present
        expect(product.shopify_info.store_id).to eq("gid://shopify/Product/12345")
        expect(product.shopify_info.shopify?).to be true
      end
    end

    context "when product already exists" do
      let!(:existing_product) do
        create(:product,
          shopify_id: "gid://shopify/Product/12345",
          title: "Old Title")
      end

      it "updates the existing product" do # rubocop:todo RSpec/MultipleExpectations
        expect { creator.update_or_create! }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.title).to eq("Eve")
        expect(existing_product.shopify_info.slug).to eq("stellar-blade-eve-statue")
      end

      it "preserves existing SKU" do
        existing_product.update!(sku: "existing-sku-123")
        original_sku = existing_product.sku

        creator.update_or_create!

        expect(existing_product.reload.sku).to eq(original_sku)
      end

      it "does not overwrite existing SKU with Shopify SKU" do
        existing_product.update!(sku: "my-custom-sku")
        parsed_product_with_shopify_sku = parsed_product.merge(sku: "shopify-sku-456")
        creator = described_class.new(parsed_item: parsed_product_with_shopify_sku)

        creator.update_or_create!

        expect(existing_product.reload.sku).to eq("my-custom-sku")
      end

      it "generates SKU for existing product without SKU" do # rubocop:todo RSpec/MultipleExpectations
        existing_product.update_column(:sku, nil)

        expect { creator.update_or_create! }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.sku).to be_present
        expect(existing_product.sku).to match(/^stellar-blade-eve-light-and-dust-studio-[a-z0-9]{8}$/)
      end

      it "updates StoreInfo store_id for existing product without SKU" do # rubocop:todo RSpec/MultipleExpectations
        existing_product.update_column(:sku, nil)
        original_store_id = existing_product.shopify_info.store_id

        expect { creator.update_or_create! }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.sku).to be_present
        expect(existing_product.shopify_info.store_id).to eq("gid://shopify/Product/12345")
        expect(existing_product.shopify_info.store_id).to eq(original_store_id)
      end

      it "uses Shopify SKU when updating existing product without SKU" do # rubocop:todo RSpec/MultipleExpectations
        existing_product.update_column(:sku, nil)
        parsed_product_with_shopify_sku = parsed_product.merge(sku: "shopify-sku-new-789")
        creator_with_sku = described_class.new(parsed_item: parsed_product_with_shopify_sku)

        expect { creator_with_sku.update_or_create! }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.sku).to eq("shopify-sku-new-789")
        expect(existing_product.sku).not_to match(/-[a-z0-9]{8}$/)
      end

      it "updates product attributes when syncing without SKU" do # rubocop:todo RSpec/MultipleExpectations
        existing_product.update_columns(sku: nil, title: "Old Title")

        expect { creator.update_or_create! }.not_to change(Product, :count)

        existing_product.reload
        expect(existing_product.title).to eq("Eve")
        expect(existing_product.shopify_info.slug).to eq("stellar-blade-eve-statue")
        expect(existing_product.sku).to be_present
        expect(existing_product.shopify_info.store_id).to eq("gid://shopify/Product/12345")
      end

      context "when syncing product that has StoreInfo but no store_id" do
        context "when StoreInfo has slug but no store_id" do
          let!(:existing_product) do
            create(:product).tap do |p|
              # Update the existing StoreInfo to have slug but no store_id
              # This simulates a product that was pushed but not pulled yet
              p.shopify_info.update_columns(store_id: nil, slug: "stellar-blade-eve-statue")
            end
          end

          it "finds the existing product by its StoreInfo slug" do
            expect { creator.update_or_create! }.not_to change(Product, :count)
          end

          it "updates the store_id in the existing StoreInfo" do # rubocop:todo RSpec/MultipleExpectations
            # Before syncing, store_id should be nil
            expect(existing_product.shopify_info.store_id).to be_nil

            # This should NOT create a new product, but update the existing one
            expect { creator.update_or_create! }.not_to change(Product, :count)

            # After syncing, store_id should be set
            existing_product.reload
            expect(existing_product.shopify_info.store_id).to eq("gid://shopify/Product/12345")
          end
        end
      end
    end

    context "when Shopify provides SKU" do
      let(:parsed_product_with_shopify_sku) do
        parsed_product.merge(sku: "shopify-provided-sku-789")
      end

      it "uses Shopify SKU instead of generating from full_title" do
        creator = described_class.new(parsed_item: parsed_product_with_shopify_sku)
        creator.update_or_create!

        product = Product.last
        expect(product.sku).to eq("shopify-provided-sku-789")
      end
    end

    context "when SKU already exists" do
      let!(:existing_product) do
        create(:product, sku: "stellar-blade-eve-light-and-dust-studio")
      end

      it "generates unique SKU using UUID" do
        creator.update_or_create!
        product = Product.last

        expect(product.sku).to match(/^stellar-blade-eve-light-and-dust-studio-[a-z0-9]{8}$/)
        expect(product.sku).not_to eq(existing_product.sku)
      end

      context "with multiple collisions" do
        let!(:existing_product2) do
          create(:product, sku: "stellar-blade-eve-light-and-dust-studio-abc12345")
        end

        it "generates unique SKU using UUID for each attempt" do
          creator.update_or_create!
          product = Product.last

          # Each SKU should have unique UUID suffixes
          expect(product.sku).to match(/^stellar-blade-eve-light-and-dust-studio-[a-z0-9]{8}$/)
          expect(product.sku).not_to eq(existing_product.sku)
          expect(product.sku).not_to eq(existing_product2.sku)
        end
      end

      context "when pulling an already synced product" do
        let!(:existing_product) do
          create(:product, sku: "mogu-studio-tifa").tap do |p|
            p.shopify_info.update!(store_id: "gid://shopify/Product/99999")
          end
        end

        let(:parsed_product_existing) do
          {
            shopify_id: "gid://shopify/Product/99999",
            store_link: "tifa-statue",
            title: "Tifa",
            franchise: "Final Fantasy VII",
            size: "1:4",
            shape: "Statue",
            brand: "Mogu Studio"
          }
        end

        let(:creator_existing) { described_class.new(parsed_item: parsed_product_existing) }

        it "preserves existing SKU when re-syncing" do
          expect { creator_existing.update_or_create! }.not_to change(Product, :count)

          existing_product.reload
          expect(existing_product.sku).to eq("mogu-studio-tifa")
        end
      end

      context "when SKU race condition occurs" do
        let(:parsed_product_race) do
          {
            shopify_id: "gid://shopify/Product/race",
            store_link: "race-test",
            title: "Race Test",
            franchise: "Test Franchise",
            size: nil,
            shape: "Statue",
            brand: nil
          }
        end

        let(:creator_race) { described_class.new(parsed_item: parsed_product_race) }

        before do
          # Create a product with the same SKU that would be generated
          create(:product, sku: "test-franchise-race-test")
        end

        it "handles SKU collision and generates unique SKU" do
          # This should succeed by generating a unique SKU
          expect { creator_race.update_or_create! }.not_to raise_error

          product = Product.last
          expect(product.sku).to start_with("test-franchise-race-test-")
          expect(product.sku).not_to eq("test-franchise-race-test")
          expect(product.sku).to match(/-?[a-z0-9]{8}$/)
        end
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
        creator = described_class.new(parsed_item: parsed_product_with_nil_values)
        expect { creator.update_or_create! }.not_to raise_error
      end
    end

    context "full title generation from parsed data" do
      it "builds full title with brand" do
        creator.update_or_create!
        product = Product.last
        expect(product.full_title).to eq("Stellar Blade — Eve | Light and Dust Studio")
      end

      it "builds full title without brand" do
        parsed_product_without_brand = parsed_product.merge(brand: nil)
        creator = described_class.new(parsed_item: parsed_product_without_brand)
        creator.update_or_create!

        product = Product.last
        expect(product.full_title).to eq("Stellar Blade — Eve")
      end

      it "builds full title when title equals franchise" do
        parsed_product_same_title = parsed_product.merge(
          title: "Stellar Blade",
          franchise: "Stellar Blade",
          brand: "Light and Dust Studio"
        )
        creator = described_class.new(parsed_item: parsed_product_same_title)
        creator.update_or_create!

        product = Product.last
        expect(product.full_title).to eq("Stellar Blade | Light and Dust Studio")
      end

      it "builds full title when title equals franchise without brand" do
        parsed_product_same_title = parsed_product.merge(
          title: "Stellar Blade",
          franchise: "Stellar Blade",
          brand: nil
        )
        creator = described_class.new(parsed_item: parsed_product_same_title)
        creator.update_or_create!

        product = Product.last
        expect(product.full_title).to eq("Stellar Blade")
      end
    end
  end
end
