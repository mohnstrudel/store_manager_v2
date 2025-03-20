require "rails_helper"

RSpec.describe SyncShopifyVariationsJob do
  let(:job) { described_class.new }
  let(:product) { create(:product) }

  describe "#perform" do
    context "with different variation types" do
      let(:parsed_variations) do
        [
          {
            "id" => "gid://shopify/ProductVariant/12345",
            "title" => "Red / Large / Deluxe",
            "options" => [
              {"value" => "Red", "name" => "Color"},
              {"value" => "Large", "name" => "Size"},
              {"value" => "Deluxe", "name" => "Edition"}
            ]
          },
          {
            "id" => "gid://shopify/ProductVariant/67890",
            "title" => "Blue / 1:6 / Standard",
            "options" => [
              {"value" => "Blue", "name" => "Color"},
              {"value" => "1:6", "name" => "Scale"},
              {"value" => "Standard", "name" => "Version"}
            ]
          }
        ]
      end

      before do
        job.perform(product, parsed_variations)
      end

      it "creates the correct number of variations" do
        expect(product.variations.count).to eq(2)
      end

      it "creates variations with correct attributes" do
        red_variation = product.variations.find_by(shopify_id: "gid://shopify/ProductVariant/12345")
        expect(red_variation).to have_attributes(
          color: Color.find_by(value: "Red"),
          size: Size.find_by(value: "Large"),
          version: Version.find_by(value: "Deluxe")
        )

        blue_variation = product.variations.find_by(shopify_id: "gid://shopify/ProductVariant/67890")
        expect(blue_variation).to have_attributes(
          color: Color.find_by(value: "Blue"),
          size: Size.find_by(value: "1:6"),
          version: Version.find_by(value: "Standard")
        )
      end

      it "creates all six different values in the database" do
        # Check that all colors are created
        expect(Color.where(value: ["Red", "Blue"]).count).to eq(2)

        # Check that all sizes are created
        expect(Size.where(value: ["Large", "1:6"]).count).to eq(2)

        # Check that all versions are created
        expect(Version.where(value: ["Deluxe", "Standard"]).count).to eq(2)

        # Total count of all values
        expect(Color.count + Size.count + Version.count).to eq(6)
      end
    end

    context "when variation already exists" do
      let!(:existing_color) { create(:color, value: "Green") }
      let!(:existing_size) { create(:size, value: "Medium") }
      let!(:existing_version) { create(:version, value: "Regular") }
      let!(:existing_variation) do
        create(:variation,
          product: product,
          color: existing_color,
          size: existing_size,
          version: existing_version)
      end

      let(:parsed_variations) do
        [
          {
            "id" => "gid://shopify/ProductVariant/12345",
            "title" => "Green / Medium / Regular",
            "options" => [
              {"value" => "Green", "name" => "Color"},
              {"value" => "Medium", "name" => "Size"},
              {"value" => "Regular", "name" => "Version"}
            ]
          }
        ]
      end

      it "updates existing variation instead of creating a duplicate" do
        expect {
          job.perform(product, parsed_variations)
        }.not_to change(Variation, :count)

        existing_variation.reload
        expect(existing_variation.shopify_id).to eq("gid://shopify/ProductVariant/12345")
      end
    end

    context "with empty options" do
      let(:parsed_variations) do
        [
          {
            "shopify_id" => "gid://shopify/ProductVariant/12345",
            "title" => "Default Title",
            "options" => []
          }
        ]
      end

      it "doesn't create a variation" do
        expect {
          job.perform(product, parsed_variations)
        }.not_to change(Variation, :count)
      end
    end
  end
end
