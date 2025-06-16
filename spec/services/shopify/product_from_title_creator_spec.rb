require "rails_helper"

RSpec.describe Shopify::ProductFromTitleCreator do
  describe "#call" do
    let(:api_title) { "Stellar Blade - Eve | 1:4 Resin Statue | Light and Dust Studio" }
    let(:creator) { described_class.new(api_title: api_title) }

    before do
      allow_any_instance_of(Shopify::ProductParser).to receive(:parse_product_title).and_return(
        ["Eve", "Stellar Blade", "1:4", "Statue", "Light and Dust Studio"]
      )
    end

    context "when product doesn't exist" do
      it "creates a new product with correct attributes" do
        expect { creator.call }.to change(Product, :count).by(1)
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
    end

    context "when product already exists" do
      let!(:existing_product) do
        create(:product,
          title: "Eve",
          franchise: create(:franchise, title: "Stellar Blade"),
          shape: create(:shape, title: "Statue"))
      end

      it "finds the existing product" do
        expect { creator.call }.not_to change(Product, :count)
        expect(creator.call).to eq(existing_product)
      end

      it "adds new relations if they don't exist" do
        expect { creator.call }.to change(Brand, :count).by(1)
          .and change(Size, :count).by(1)

        product = Product.last
        expect(product.brands.first.title).to eq("Light and Dust Studio")
        expect(product.sizes.first.value).to eq("1:4")
      end
    end

    context "with empty title" do
      let(:creator) { described_class.new(api_title: "") }

      it "raises an error" do
        allow_any_instance_of(Shopify::ProductParser).to receive(:parse_product_title)
          .and_raise(ArgumentError, "Title cannot be blank")

        expect { creator.call }.to raise_error(ArgumentError, "Title cannot be blank")
      end
    end

    context "with missing relations" do
      before do
        allow_any_instance_of(Shopify::ProductParser).to receive(:parse_product_title).and_return(
          ["Eve", "Stellar Blade", nil, "Statue", nil]
        )
      end

      it "creates product without optional relations" do
        expect { creator.call }.to change(Product, :count).by(1)
          .and change(Franchise, :count).by(1)
          .and change(Shape, :count).by(1)
          .and change(Brand, :count).by(0)
          .and change(Size, :count).by(0)

        product = Product.last
        expect(product.title).to eq("Eve")
        expect(product.franchise.title).to eq("Stellar Blade")
        expect(product.shape.title).to eq("Statue")
        expect(product.brands).to be_empty
        expect(product.sizes).to be_empty
      end
    end

    context "with existing relations" do
      let!(:existing_brand) { create(:brand, title: "Light and Dust Studio") }
      let!(:existing_size) { create(:size, value: "1:4") }

      it "uses existing relations instead of creating new ones" do
        expect { creator.call }.to change(Product, :count).by(1)
          .and change(Brand, :count).by(0)
          .and change(Size, :count).by(0)

        product = Product.last
        expect(product.brands).to include(existing_brand)
        expect(product.sizes).to include(existing_size)
      end
    end
  end
end
