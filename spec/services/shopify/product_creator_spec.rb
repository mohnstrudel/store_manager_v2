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
        expect(product.shopify_id).to eq("gid://shopify/Product/12345")
        expect(product.store_link).to eq("stellar-blade-eve-statue")
        expect(product.title).to eq("Eve")
        expect(product.franchise.title).to eq("Stellar Blade")
        expect(product.shape.title).to eq("Statue")
        expect(product.brands.first.title).to eq("Light and Dust Studio")
        expect(product.sizes.first.value).to eq("1:4")
      end

      it "enqueues sync jobs for editions and images" do # rubocop:todo RSpec/MultipleExpectations
        allow(Shopify::PullEditionsJob).to receive(:perform_later)
        allow(Shopify::PullImagesJob).to receive(:perform_later)

        creator.update_or_create!

        expect(Shopify::PullEditionsJob).to have_received(:perform_later)
        expect(Shopify::PullImagesJob).to have_received(:perform_later)
      end

      it "generates correct full title" do
        creator.update_or_create!
        product = Product.last
        expect(product.full_title).to eq(Product.generate_full_title(product))
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
        expect(existing_product.store_link).to eq("stellar-blade-eve-statue")
      end
    end

    context "with invalid input" do
      it "raises ArgumentError if parsed_item is not a Hash" do
        expect { described_class.new(parsed_item: "not a hash") }
          .to raise_error(ArgumentError, "parsed_item must be a Hash")
      end

      it "raises ArgumentError if parsed_item is blank" do
        expect { described_class.new(parsed_item: {}) }
          .to raise_error(ArgumentError, "parsed_item cannot be blank")
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
  end

  describe "#update_or_create_by_title" do
    let(:creator_by_title) { described_class.new(parsed_title: "Stellar Blade - Eve | 1:4 Resin Statue | Light and Dust Studio") }

    before do
      # rubocop:todo RSpec/AnyInstance
      allow_any_instance_of(Shopify::ProductParser).to receive(:parse_product_title).and_return(
        # rubocop:enable RSpec/AnyInstance
        ["Eve", "Stellar Blade", "1:4", "Statue", "Light and Dust Studio"]
      )
    end
  end
end
