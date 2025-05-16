require "rails_helper"

RSpec.describe Shopify::EditionCreator do
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
      it "creates a new edition with correct attributes" do
        expect { creator.update_or_create! }.to change(Edition, :count).by(1)

        edition = Edition.last
        expect(edition.shopify_id).to eq("gid://shopify/ProductVariant/12345")
        expect(edition.product).to eq(product)
        expect(edition.color.value).to eq("Red")
        expect(edition.size.value).to eq("Large")
        expect(edition.version.value).to eq("Deluxe")
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

        edition = Edition.last
        expect(edition.color).to eq(existing_color)
      end
    end

    context "when edition already exists" do
      let!(:existing_edition) do
        create(:edition,
          product: product,
          shopify_id: "gid://shopify/ProductVariant/12345")
      end

      it "updates the existing edition" do
        expect { creator.update_or_create! }.not_to change(Edition, :count)

        existing_edition.reload
        expect(existing_edition.color.value).to eq("Red")
        expect(existing_edition.size.value).to eq("Large")
        expect(existing_edition.version.value).to eq("Deluxe")
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
