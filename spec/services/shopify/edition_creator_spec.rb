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
      it "creates a new edition with correct attributes" do # rubocop:todo RSpec/MultipleExpectations
        expect { creator.update_or_create! }.to change(Edition, :count).by(1)

        edition = Edition.last
        expect(edition.shopify_id).to eq("gid://shopify/ProductVariant/12345")
        expect(edition.product).to eq(product)
        expect(edition.color.value).to eq("Red")
        expect(edition.size.value).to eq("Large")
        expect(edition.version.value).to eq("Deluxe")

        product.reload
        expect(product.colors).to include(edition.color)
        expect(product.sizes).to include(edition.size)
        expect(product.versions).to include(edition.version)
      end

      it "creates associated attribute records if they don't exist" do # rubocop:todo RSpec/MultipleExpectations
        expect { creator.update_or_create! }.to change(Color, :count).by(1)
          .and change(Size, :count).by(1)
          .and change(Version, :count).by(1)

        product.reload
        expect(product.colors.count).to eq(1)
        expect(product.sizes.count).to eq(1)
        expect(product.versions.count).to eq(1)
      end

      it "reuses existing attribute records" do # rubocop:todo RSpec/MultipleExpectations
        existing_color = create(:color, value: "Red")

        expect { creator.update_or_create! }.to change(Color, :count).by(0) # rubocop:todo RSpec/ChangeByZero
          .and change(Size, :count).by(1)
          .and change(Version, :count).by(1)

        edition = Edition.last
        expect(edition.color).to eq(existing_color)

        product.reload
        expect(product.colors).to include(existing_color)
      end
    end

    context "when edition already exists" do
      let!(:existing_edition) do
        create(:edition,
          product: product,
          shopify_id: "gid://shopify/ProductVariant/12345")
      end

      it "updates the existing edition" do # rubocop:todo RSpec/MultipleExpectations
        expect { creator.update_or_create! }.not_to change(Edition, :count)

        existing_edition.reload
        expect(existing_edition.color.value).to eq("Red")
        expect(existing_edition.size.value).to eq("Large")
        expect(existing_edition.version.value).to eq("Deluxe")

        product.reload
        expect(product.colors.map(&:value)).to include("Red")
        expect(product.sizes.map(&:value)).to include("Large")
        expect(product.versions.map(&:value)).to include("Deluxe")
      end
    end

    context "with invalid data" do
      it "raises error when product is blank" do
        expect { described_class.new(nil, parsed_variant) }.to raise_error(ArgumentError, "Expected a Product")
      end

      it "returns nil and does not create an edition" do # rubocop:todo RSpec/MultipleExpectations
        creator = described_class.new(product, {options: []})
        expect { creator.update_or_create! }.not_to change(Edition, :count)
        expect(creator.update_or_create!).to be_nil
      end
    end

    context "when edition_attrs is blank" do
      it "returns nil and does not create an edition" do # rubocop:todo RSpec/MultipleExpectations
        # Simulate options that do not match any known attribute names
        parsed_variant = {
          id: "gid://shopify/ProductVariant/99999",
          options: [
            {name: "Unknown", value: "Mystery"}
          ]
        }
        creator = described_class.new(product, parsed_variant)
        expect { creator.update_or_create! }.not_to change(Edition, :count)
        expect(creator.update_or_create!).to be_nil
      end
    end
  end
end
