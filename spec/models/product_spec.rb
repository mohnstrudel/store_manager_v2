# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  full_title   :string
#  image        :string
#  sku          :string
#  slug         :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  franchise_id :bigint           not null
#  shape_id     :bigint           not null
#  shopify_id   :string
#  woo_id       :string
#
require "rails_helper"

RSpec.describe Product do
  describe "#generate_full_title" do
    let(:franchise)	{ create(:franchise, title: "Elden Ring") }
    let(:brand)	{ create(:brand, title: "Coolbear Studio") }
    let(:brand2)	{ create(:brand, title: "Prime 1 Studio") }

    context "when product is created" do
      it "composes full title like 'franchise.title — product.title | brand.title'" do
        product = create(:product_with_brands, title: "Malenia", franchise:, brand_title: brand.title)
        canonical_title = "#{franchise.title} — #{product.title} | #{brand.title}"

        expect(product.full_title).to eq(canonical_title)
      end

      it "handles multiple brands" do
        product = create(:product, title: "Malenia", franchise:)
        product.brands << [brand, brand2]
        product.send(:update_full_title)

        expected_title = "#{franchise.title} — #{product.title} | #{brand.title}, #{brand2.title}"
        expect(product.full_title).to eq(expected_title)
      end

      it "handles product title same as franchise" do
        product = create(:product_with_brands, title: "Elden Ring", franchise:, brand_title: brand.title)
        expected_title = "#{franchise.title} | #{brand.title}"

        expect(product.full_title).to eq(expected_title)
      end

      it "handles product without brands" do
        product = create(:product, title: "Malenia", franchise:)
        expected_title = "#{franchise.title} — #{product.title}"

        expect(product.full_title).to eq(expected_title)
      end
    end
  end

  describe "#build_editions" do
    let(:product) { create(:product) }
    let(:size1) { create(:size, value: "S") } # rubocop:todo RSpec/IndexedLet
    let(:size2) { create(:size, value: "M") } # rubocop:todo RSpec/IndexedLet
    let(:version1) { create(:version, value: "Regular") } # rubocop:todo RSpec/IndexedLet
    let(:version2) { create(:version, value: "Limited") } # rubocop:todo RSpec/IndexedLet
    let(:version3) { create(:version, value: "Pro") } # rubocop:todo RSpec/IndexedLet
    let(:color1) { create(:color, value: "Red") } # rubocop:todo RSpec/IndexedLet
    let(:color2) { create(:color, value: "Blue") } # rubocop:todo RSpec/IndexedLet
    let(:color3) { create(:color, value: "Green") } # rubocop:todo RSpec/IndexedLet

    context "when product has no attributes" do
      it "builds no editions" do
        product.build_editions
        expect(product.editions).to be_empty
      end
    end

    context "when product has only sizes" do
      before do
        product.sizes << [size1, size2]
      end

      it "builds editions for each size" do
        product.build_editions
        expect(product.editions.size).to eq(2)
      end
    end

    context "when product has only versions" do
      before do
        product.versions << [version1]
      end

      it "builds editions for each size" do
        product.build_editions
        expect(product.editions.size).to eq(1)
      end
    end

    context "when product has only colors" do
      before do
        product.colors << [color1, color2]
      end

      it "builds editions for each size" do
        product.build_editions
        expect(product.editions.size).to eq(2)
      end
    end

    context "when product has sizes and versions" do
      before do
        product.sizes << [size1, size2]
        product.versions << [version1, version2]
      end

      it "builds editions for each size-version combination" do
        product.build_editions
        expect(product.editions.size).to eq(4) # 2 sizes × 2 versions
      end
    end

    context "when product has sizes, versions and colors" do
      before do
        product.sizes << [size1, size2]
        product.versions << [version1, version2, version3]
        product.colors << [color1, color2, color3]
      end

      it "builds editions for each size-version-color combination" do
        product.build_editions
        expect(product.editions.size).to eq(18)
      end
    end

    context "when product has only versions and colors" do
      before do
        product.versions << [version1, version2]
        product.colors << [color1, color2, color3]
      end

      it "builds editions for each version-color combination" do
        product.build_editions
        expect(product.editions.size).to eq(6) # 2 versions × 3 colors
      end
    end

    context "when product has only one size and colors" do
      before do
        product.sizes << [size1]
        product.colors << [color1, color2, color3]
      end

      it "builds editions for each size-color combination" do
        product.build_editions
        expect(product.editions.size).to eq(3) # 1 size × 3 colors
      end
    end

    context "when product attributes are removed" do
      before do
        product.sizes << [size1, size2]
        product.versions << [version1, version2]
        product.colors << [color1, color2]
        product.build_editions
        product.save
      end

      it "removes editions when size is removed" do
        product.sizes.delete(size1)
        product.build_editions
        expect(product.editions.count(&:marked_for_destruction?)).to eq(4)
      end

      it "removes editions when version is removed" do
        product.versions.delete(version1)
        product.build_editions
        expect(product.editions.count(&:marked_for_destruction?)).to eq(4)
      end

      it "removes editions when color is removed" do
        product.colors.delete(color1)
        product.build_editions
        expect(product.editions.count(&:marked_for_destruction?)).to eq(4)
      end

      it "keeps valid editions when removing attributes" do
        initial_editions_count = product.editions.count
        product.colors.delete(color1)
        product.build_editions
        expect(product.editions.count { |element| !element.marked_for_destruction? }).to eq(initial_editions_count / 2)
      end
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe "#shopify_published?" do
    context "when product has not been published to Shopify" do
      it "returns false" do
        product = build(:product)
        # Create product without store_infos to simulate unpublished state
        product.save(validate: false)

        expect(product.shopify_published?).to be false
      end
    end

    context "when product has been published to Shopify" do
      it "returns true" do
        product = create(:product)

        expect(product.shopify_published?).to be true
      end
    end
  end

  describe "description field" do
    context "when product has a description" do
      it "stores HTML content" do
        html_description = "<p>This is a <strong>great</strong> product with <em>features</em>.</p>"
        product = create(:product, description: html_description)

        expect(product.description.body.to_html.strip).to eq(html_description)
      end

      it "allows updating description" do
        product = create(:product, description: "<p>Original description</p>")
        product.update(description: "<p>Updated <strong>description</strong></p>")

        expect(product.reload.description.body.to_html.strip).to eq("<p>Updated <strong>description</strong></p>")
      end
    end

    context "when product has no description" do
      it "allows creating product without description" do
        product = create(:product, description: nil)

        expect(product.description.body).to be_blank
      end

      it "allows empty string description" do
        product = create(:product, description: "")

        expect(product.description.body).to be_blank
      end
    end
  end

  describe ".parse_shopify_title" do
    context "with full Shopify title format" do
      it "parses title with franchise, product, size, shape, and brand" do
        title = "Elden Ring - Malenia | 1:4 | Resin Statue | Prime 1 Studio"
        product_title, franchise, size, shape, brand = described_class.parse_shopify_title(title)

        expect(product_title).to eq("Malenia")
        expect(franchise).to eq("Elden Ring")
        expect(size).to eq("1:4")
        expect(shape).to eq("Statue")
        expect(brand).to eq("Prime 1 Studio")
      end
    end

    context "with title without explicit brand" do
      it "parses title with franchise, product, size, and shape only" do
        title = "Berserk - Guts | 1:3 | Resin Bust"
        product_title, franchise, size, shape, brand = described_class.parse_shopify_title(title)

        expect(product_title).to eq("Guts")
        expect(franchise).to eq("Berserk")
        expect(size).to eq("1:3")
        expect(shape).to eq("Bust")
        expect(brand).to be_nil
      end
    end

    context "with title when franchise equals product" do
      it "parses title correctly" do
        title = "Elden Ring - Elden Ring | 1:6 | Resin Statue | Iron Studios"
        product_title, franchise, size, shape, brand = described_class.parse_shopify_title(title)

        expect(product_title).to eq("Elden Ring")
        expect(franchise).to eq("Elden Ring")
        expect(size).to eq("1:6")
        expect(shape).to eq("Statue")
        expect(brand).to eq("Iron Studios")
      end
    end

    context "with title using 'von' brand identifier" do
      it "extracts brand name after 'von'" do
        title = "Game - Character | 1:4 | Resin Statue von Coolbear Studio"
        _product_title, _franchise, _size, _shape, brand = described_class.parse_shopify_title(title)

        # The brand is parsed by Brand.parse_brand which extracts "Coolbear Studio"
        expect(brand).to eq("Coolbear Studio")
      end
    end

    context "with blank title" do
      it "raises ArgumentError" do
        expect {
          described_class.parse_shopify_title("")
        }.to raise_error(ArgumentError, "Product title cannot be blank")
      end
    end
  end

  describe "#assign_brand" do
    let(:product) { create(:product) }

    context "with valid brand title" do
      it "creates and assigns a new brand" do
        brand = product.assign_brand("Prime 1 Studio")

        expect(product.brands).to include(brand)
        expect(brand.title).to eq("Prime 1 Studio")
      end

      it "finds and assigns existing brand" do
        existing_brand = create(:brand, title: "Iron Studios")
        brand = product.assign_brand("Iron Studios")

        expect(product.brands).to include(existing_brand)
        expect(brand).to eq(existing_brand)
      end

      it "updates full_title after assigning brand" do
        expect {
          product.assign_brand("Test Brand")
        }.to change { product.full_title }
      end
    end

    context "with nil brand title" do
      it "returns nil and does not assign brand" do
        result = product.assign_brand(nil)

        expect(result).to be_nil
        expect(product.brands).to be_empty
      end
    end

    context "with empty string brand title" do
      it "returns nil and does not assign brand" do
        result = product.assign_brand("")

        expect(result).to be_nil
        expect(product.brands).to be_empty
      end
    end
  end

  describe "#assign_size" do
    let(:product) { create(:product) }

    context "with single size value" do
      it "creates and assigns a new size" do
        size = product.assign_size("1:4")

        expect(product.sizes).to include(size)
        expect(size.value).to eq("1:4")
      end

      it "finds and assigns existing size" do
        existing_size = create(:size, value: "1:6")
        size = product.assign_size("1:6")

        expect(product.sizes).to include(existing_size)
        expect(size).to eq(existing_size)
      end
    end

    context "with array of size values" do
      it "creates and assigns multiple sizes" do
        sizes = product.assign_size(["1:4", "1:6"])

        expect(sizes).to be_a(Size) # Returns first size
        expect(product.sizes.count).to eq(2)
        expect(product.sizes.pluck(:value)).to contain_exactly("1:4", "1:6")
      end
    end

    context "with nil size value" do
      it "returns nil and does not assign size" do
        result = product.assign_size(nil)

        expect(result).to be_nil
        expect(product.sizes).to be_empty
      end
    end

    context "with empty string size value" do
      it "returns nil and does not assign size" do
        result = product.assign_size("")

        expect(result).to be_nil
        expect(product.sizes).to be_empty
      end
    end
  end

  describe "#generate_sku_from_shopify" do
    let(:product) { create(:product) }

    context "with valid shopify SKU" do
      it "assigns the shopify SKU" do
        sku = product.generate_sku_from_shopify("HS-ELDEN-001")

        expect(product.sku).to eq("HS-ELDEN-001")
      end
    end

    context "with nil shopify SKU" do
      it "generates SKU from full_title with random suffix" do
        sku = product.generate_sku_from_shopify(nil)

        # Parameterize converts special characters to hyphens and truncates to 50 chars
        # plus 8-char hex suffix = max ~58 chars
        expect(sku).to be_a(String)
        expect(sku.length).to be > 30 # Minimum length check
        expect(sku).to match(/^[a-z0-9-]+-[a-f0-9]{8}$/) # Ends with 8-char hex
      end

      it "assigns generated SKU to product" do
        product.generate_sku_from_shopify(nil)

        expect(product.sku).to be_present
      end
    end

    context "with empty string shopify SKU" do
      it "generates SKU from full_title with random suffix" do
        sku = product.generate_sku_from_shopify("")

        expect(sku).to be_a(String)
        expect(sku).to match(/^[a-z0-9-]+-[a-f0-9]{8}$/) # Ends with 8-char hex
      end
    end
  end

  describe ".recently_synced" do
    let(:old_sync_product) { create(:product) }
    let(:new_sync_product) { create(:product) }

    before do
      old_sync_product.shopify_info.update_column(:pull_time, 1.day.ago)
      new_sync_product.shopify_info.update_column(:pull_time, 1.hour.ago)
    end

    it "orders products by most recent pull_time" do
      expect(described_class.recently_synced).to eq([new_sync_product, old_sync_product])
    end

    it "only includes products synced with Shopify" do
      unsynced_product = create(:product, shopify_id: nil)

      expect(described_class.recently_synced).not_to include(unsynced_product)
    end
  end
end
