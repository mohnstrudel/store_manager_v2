require "rails_helper"

RSpec.describe Shopify::VariationCreator do
  let(:product) { create(:product) }
  let(:parsed_variant) do
    {
      id: "gid://shopify/ProductVariant/12345",
      options: [
        {name: "Color", value: "Red"},
        {name: "Size", value: "Large"},
        {name: "Version", value: "Deluxe"}
      ]
    }
  end
  let(:creator) { described_class.new(product, parsed_variant) }

  describe "#update_or_create!" do
    context "with valid data" do
      it "creates a new variation with correct attributes" do
        expect { creator.update_or_create! }.to change(Variation, :count).by(1)

        variation = Variation.last
        expect(variation.shopify_id).to eq("gid://shopify/ProductVariant/12345")
        expect(variation.product).to eq(product)
        expect(variation.color.value).to eq("Red")
        expect(variation.size.value).to eq("Large")
        expect(variation.version.value).to eq("Deluxe")
      end

      it "creates associated attribute records if they don't exist" do
        expect { creator.update_or_create! }.to change(Color, :count).by(1)
          .and change(Size, :count).by(1)
          .and change(Version, :count).by(1)
      end

      it "reuses existing attribute records" do
        existing_color = create(:color, value: "Red")

        expect { creator.update_or_create! }.to change(Color, :count).by(0)
          .and change(Size, :count).by(1)
          .and change(Version, :count).by(1)

        variation = Variation.last
        expect(variation.color).to eq(existing_color)
      end
    end

    context "when variation already exists" do
      let!(:existing_variation) do
        create(:variation,
          product: product,
          shopify_id: "gid://shopify/ProductVariant/12345")
      end

      it "updates the existing variation" do
        expect { creator.update_or_create! }.not_to change(Variation, :count)

        existing_variation.reload
        expect(existing_variation.color.value).to eq("Red")
        expect(existing_variation.size.value).to eq("Large")
        expect(existing_variation.version.value).to eq("Deluxe")
      end
    end

    context "with invalid data" do
      it "raises error when product is blank" do
        creator = described_class.new(nil, parsed_variant)
        expect { creator.update_or_create! }.to raise_error(ArgumentError, "Product must be present")
      end

      it "raises error when variant options are blank" do
        creator = described_class.new(product, {options: []})
        expect { creator.update_or_create! }.to raise_error(ArgumentError, "Variant must be present")
      end
    end
  end
end
