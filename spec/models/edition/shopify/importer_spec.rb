# frozen_string_literal: true

require "rails_helper"

RSpec.describe Edition::Shopify::Importer do
  let(:product) { create(:product) }
  let(:parsed_variant) do
    {
      store_id: "gid://shopify/ProductVariant/12345",
      sku: "TEST-SKU-001",
      selling_price: "299.99",
      purchase_cost: "150.00",
      weight: 2.5,
      options: [
        {name: "Color", value: "Red"},
        {name: "Size", value: "Large"},
        {name: "Version", value: "Deluxe"}
      ]
    }
  end

  describe ".import!" do
    it "creates a new edition with correct attributes" do # rubocop:todo RSpec/MultipleExpectations
      expect { described_class.import!(product, parsed_variant) }.to change(Edition, :count).by(1)

      edition = Edition.last
      expect(edition.shopify_info.store_id).to eq("gid://shopify/ProductVariant/12345")
      expect(edition.product).to eq(product)
      expect(edition.sku).to eq("TEST-SKU-001")
      expect(edition.selling_price).to eq(BigDecimal("299.99"))
      expect(edition.purchase_cost).to eq(BigDecimal("150.00"))
      expect(edition.weight).to eq(BigDecimal("2.5"))
      expect(edition.color.value).to eq("Red")
      expect(edition.size.value).to eq("Large")
      expect(edition.version.value).to eq("Deluxe")

      product.reload
      expect(product.colors).to include(edition.color)
      expect(product.sizes).to include(edition.size)
      expect(product.versions).to include(edition.version)
    end

    it "saves Shopify ID to StoreInfo" do
      described_class.import!(product, parsed_variant)
      edition = Edition.last
      expect(edition.shopify_info).to be_present
      expect(edition.shopify_info.store_id).to eq("gid://shopify/ProductVariant/12345")
      expect(edition.shopify_info.shopify?).to be true
    end

    it "updates pull_time in StoreInfo" do
      described_class.import!(product, parsed_variant)
      edition = Edition.last
      expect(edition.shopify_info.pull_time).to be_within(1.second).of(Time.zone.now)
    end

    context "with ext_created_at and ext_updated_at" do
      let(:parsed_variant_with_timestamps) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Color", value: "Red"}
          ],
          store_info: {
            ext_created_at: 1.day.ago.iso8601,
            ext_updated_at: 1.hour.ago.iso8601
          }
        }
      end

      it "saves ext_created_at and ext_updated_at to StoreInfo" do
        described_class.import!(product, parsed_variant_with_timestamps)
        edition = Edition.last
        expect(edition.shopify_info.ext_created_at).to eq(Time.zone.parse(parsed_variant_with_timestamps[:store_info][:ext_created_at]))
        expect(edition.shopify_info.ext_updated_at).to eq(Time.zone.parse(parsed_variant_with_timestamps[:store_info][:ext_updated_at]))
      end
    end

    context "without store_info" do
      let(:parsed_variant_without_store_info) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Color", value: "Red"}
          ]
        }
      end

      it "does not set ext_created_at and ext_updated_at" do
        described_class.import!(product, parsed_variant_without_store_info)
        edition = Edition.last
        expect(edition.shopify_info.ext_created_at).to be_nil
        expect(edition.shopify_info.ext_updated_at).to be_nil
      end
    end

    it "creates associated attribute records if they don't exist" do # rubocop:todo RSpec/MultipleExpectations
      expect { described_class.import!(product, parsed_variant) }.to change(Color, :count).by(1)
        .and change(Size, :count).by(1)
        .and change(Version, :count).by(1)

      product.reload
      expect(product.colors.count).to eq(1)
      expect(product.sizes.count).to eq(1)
      expect(product.versions.count).to eq(1)
    end

    it "reuses existing attribute records" do # rubocop:todo RSpec/MultipleExpectations
      existing_color = create(:color, value: "Red")

      expect { described_class.import!(product, parsed_variant) }.to change(Color, :count).by(0) # rubocop:todo RSpec/ChangeByZero
        .and change(Size, :count).by(1)
        .and change(Version, :count).by(1)

      edition = Edition.last
      expect(edition.color).to eq(existing_color)

      product.reload
      expect(product.colors).to include(existing_color)
    end

    context "when edition already exists by shopify_id" do
      let!(:existing_edition) do
        create(:edition, product: product).tap do |ed|
          ed.shopify_info.update!(store_id: "gid://shopify/ProductVariant/12345")
        end
      end

      it "updates the existing edition" do # rubocop:todo RSpec/MultipleExpectations
        expect { described_class.import!(product, parsed_variant) }.not_to change(Edition, :count)

        existing_edition.reload
        expect(existing_edition.color.value).to eq("Red")
        expect(existing_edition.size.value).to eq("Large")
        expect(existing_edition.version.value).to eq("Deluxe")

        product.reload
        expect(product.colors.map(&:value)).to include("Red")
        expect(product.sizes.map(&:value)).to include("Large")
        expect(product.versions.map(&:value)).to include("Deluxe")
      end

      context "with updated store_info timestamps" do
        let(:parsed_variant_with_new_timestamps) do
          {
            store_id: "gid://shopify/ProductVariant/12345",
            options: [
              {name: "Color", value: "Red"}
            ],
            store_info: {
              ext_created_at: 2.days.ago.iso8601,
              ext_updated_at: 30.minutes.ago.iso8601
            }
          }
        end

        it "updates ext_created_at and ext_updated_at" do
          original_created_at = existing_edition.shopify_info.ext_created_at
          original_updated_at = existing_edition.shopify_info.ext_updated_at

          described_class.import!(product, parsed_variant_with_new_timestamps)

          existing_edition.shopify_info.reload
          expect(existing_edition.shopify_info.ext_created_at).not_to eq(original_created_at)
          expect(existing_edition.shopify_info.ext_updated_at).not_to eq(original_updated_at)
          expect(existing_edition.shopify_info.ext_created_at).to eq(Time.zone.parse(parsed_variant_with_new_timestamps[:store_info][:ext_created_at]))
          expect(existing_edition.shopify_info.ext_updated_at).to eq(Time.zone.parse(parsed_variant_with_new_timestamps[:store_info][:ext_updated_at]))
        end
      end
    end

    context "when edition already exists by attributes" do
      let!(:existing_edition) do
        color = create(:color, value: "Red")
        size = create(:size, value: "Large")
        version = create(:version, value: "Deluxe")
        create(:edition, product: product, color: color, size: size, version: version)
      end

      it "updates the existing edition with shopify_id" do # rubocop:todo RSpec/MultipleExpectations
        expect { described_class.import!(product, parsed_variant) }.not_to change(Edition, :count)

        existing_edition.reload
        expect(existing_edition.shopify_info.store_id).to eq("gid://shopify/ProductVariant/12345")
        expect(existing_edition.color.value).to eq("Red")
        expect(existing_edition.size.value).to eq("Large")
        expect(existing_edition.version.value).to eq("Deluxe")
      end
    end

    context "with blank options" do
      it "returns nil and does not create an edition" do # rubocop:todo RSpec/MultipleExpectations
        result = described_class.import!(product, {options: []})
        expect { described_class.import!(product, {options: []}) }.not_to change(Edition, :count)
        expect(result).to be_nil
      end
    end

    context "with Scale option" do
      let(:parsed_variant_with_scale) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Scale", value: "1:4"}
          ]
        }
      end

      it "maps Scale option to Size" do
        described_class.import!(product, parsed_variant_with_scale)

        edition = Edition.last
        expect(edition.size.value).to eq("1:4")
      end
    end

    context "with Edition option" do
      let(:parsed_variant_with_edition) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Edition", value: "Limited"}
          ]
        }
      end

      it "maps Edition option to Version" do
        described_class.import!(product, parsed_variant_with_edition)

        edition = Edition.last
        expect(edition.version.value).to eq("Limited")
      end
    end

    context "with Variante option (German)" do
      let(:parsed_variant_with_variante) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Variante", value: "Deutsch"}
          ]
        }
      end

      it "maps Variante option to Version" do
        described_class.import!(product, parsed_variant_with_variante)

        edition = Edition.last
        expect(edition.version.value).to eq("Deutsch")
      end
    end

    context "with Variants option (English plural)" do
      let(:parsed_variant_with_variants) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Variants", value: "Standard"}
          ]
        }
      end

      it "maps Variants option to Version" do
        described_class.import!(product, parsed_variant_with_variants)

        edition = Edition.last
        expect(edition.version.value).to eq("Standard")
      end
    end

    context "with multiple options of same type" do
      let(:parsed_variant_multiple_colors) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Color", value: "Red"},
            {name: "Color", value: "Blue"}
          ]
        }
      end

      it "associates both colors with the product" do
        described_class.import!(product, parsed_variant_multiple_colors)

        product.reload
        expect(product.colors.map(&:value)).to include("Red", "Blue")
      end
    end

    context "with single-variant product (Title option only with is_single_variant flag)" do
      let(:parsed_single_variant) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Title", value: "Default Title"}
          ],
          is_single_variant: true
        }
      end

      it "creates an edition with no options (Base Model)" do # rubocop:todo RSpec/MultipleExpectations
        result = described_class.import!(product, parsed_single_variant)
        expect(result).not_to be_nil
        expect(Edition.count).to eq(1)
        expect(Edition.last.version).to be_nil
        expect(Edition.last.size).to be_nil
        expect(Edition.last.color).to be_nil
        expect(Edition.last.title).to eq("Base Model")
      end

      context "when the product already has a base edition without Shopify linkage" do
        let!(:existing_edition) do
          create(:edition,
            product: product,
            version: nil,
            sku: "LOCAL-BASE-SKU").tap do |edition|
            edition.store_infos.destroy_all
            edition.update_columns(shopify_id: nil, woo_id: nil)
          end
        end

        it "reuses the existing base edition and attaches the Shopify store info" do # rubocop:todo RSpec/MultipleExpectations
          expect { described_class.import!(product, parsed_single_variant) }.not_to change(Edition, :count)

          existing_edition.reload
          expect(existing_edition.shopify_info.store_id).to eq("gid://shopify/ProductVariant/12345")
          expect(existing_edition.size).to be_nil
          expect(existing_edition.version).to be_nil
          expect(existing_edition.color).to be_nil
        end
      end
    end

    context "with Title option only (multi-variant product)" do
      let(:parsed_variant_with_title) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Title", value: "Default Title"}
          ],
          is_single_variant: false
        }
      end

      it "creates an edition with no attributes" do # rubocop:todo RSpec/MultipleExpectations
        result = described_class.import!(product, parsed_variant_with_title)
        expect(result).not_to be_nil
        expect(Edition.count).to eq(1)
        expect(Edition.last.color).to be_nil
        expect(Edition.last.size).to be_nil
        expect(Edition.last.version).to be_nil
      end

      context "when the product already has a nil-attribute edition without Shopify linkage" do
        let!(:existing_edition) do
          create(:edition, product: product, version: nil, sku: "LOCAL-TITLE-SKU").tap do |edition|
            edition.store_infos.destroy_all
            edition.update_columns(shopify_id: nil, woo_id: nil)
          end
        end

        it "updates the existing edition instead of creating a duplicate" do # rubocop:todo RSpec/MultipleExpectations
          expect { described_class.import!(product, parsed_variant_with_title) }.not_to change(Edition, :count)

          existing_edition.reload
          expect(existing_edition.shopify_info.store_id).to eq("gid://shopify/ProductVariant/12345")
          expect(existing_edition.color).to be_nil
          expect(existing_edition.size).to be_nil
          expect(existing_edition.version).to be_nil
        end
      end
    end

    context "with Title option and other options" do
      let(:parsed_variant_with_title_and_color) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Title", value: "Default Title"},
            {name: "Color", value: "Red"}
          ]
        }
      end

      it "skips Title and processes other options" do
        described_class.import!(product, parsed_variant_with_title_and_color)

        edition = Edition.last
        expect(edition.color.value).to eq("Red")
      end
    end

    context "with missing price, cost, and weight" do
      let(:parsed_variant_without_pricing) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          options: [
            {name: "Color", value: "Red"}
          ]
        }
      end

      it "creates an edition with default price/cost/weight values" do
        described_class.import!(product, parsed_variant_without_pricing)

        edition = Edition.last
        expect(edition.selling_price).to eq(0.0)
        expect(edition.purchase_cost).to eq(0.0)
        expect(edition.weight).to eq(0.0)
      end
    end

    context "with partial pricing data (only selling_price)" do
      let(:parsed_variant_partial_pricing) do
        {
          store_id: "gid://shopify/ProductVariant/12345",
          selling_price: "199.99",
          options: [
            {name: "Color", value: "Blue"}
          ]
        }
      end

      it "stores selling_price and leaves other fields as defaults" do
        described_class.import!(product, parsed_variant_partial_pricing)

        edition = Edition.last
        expect(edition.selling_price.to_s).to eq("199.99")
        expect(edition.purchase_cost).to eq(0.0)
        expect(edition.weight).to eq(0.0)
      end
    end
  end
end
