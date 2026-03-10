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

  describe "#build_new_editions" do
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
        product.build_new_editions
        expect(product.editions).to be_empty
      end
    end

    context "when product has only sizes" do
      before do
        product.sizes << [size1, size2]
      end

      it "builds editions for each size" do
        product.build_new_editions
        expect(product.editions.size).to eq(2)
      end
    end

    context "when product has only versions" do
      before do
        product.versions << [version1]
      end

      it "builds editions for each size" do
        product.build_new_editions
        expect(product.editions.size).to eq(1)
      end
    end

    context "when product has only colors" do
      before do
        product.colors << [color1, color2]
      end

      it "builds editions for each size" do
        product.build_new_editions
        expect(product.editions.size).to eq(2)
      end
    end

    context "when product has sizes and versions" do
      before do
        product.sizes << [size1, size2]
        product.versions << [version1, version2]
      end

      it "builds editions for each size-version combination" do
        product.build_new_editions
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
        product.build_new_editions
        expect(product.editions.size).to eq(18)
      end
    end

    context "when product has only versions and colors" do
      before do
        product.versions << [version1, version2]
        product.colors << [color1, color2, color3]
      end

      it "builds editions for each version-color combination" do
        product.build_new_editions
        expect(product.editions.size).to eq(6) # 2 versions × 3 colors
      end
    end

    context "when product has only one size and colors" do
      before do
        product.sizes << [size1]
        product.colors << [color1, color2, color3]
      end

      it "builds editions for each color without size (single size is skipped)" do
        product.build_new_editions
        expect(product.editions.size).to eq(3) # 3 colors, no size
      end

      it "does not include size in edition attributes" do
        product.build_new_editions
        expect(product.editions.map(&:size_id)).to all be_nil
      end
    end

    context "when product has only one color and no other attributes" do
      before do
        product.colors << [color1]
      end

      it "builds one edition with the color" do
        product.build_new_editions
        expect(product.editions.size).to eq(1)
        expect(product.editions.first.color_id).to eq(color1.id)
      end
    end

    context "when product has only one version and no other attributes" do
      before do
        product.versions << [version1]
      end

      it "builds one edition with the version" do
        product.build_new_editions
        expect(product.editions.size).to eq(1)
        expect(product.editions.first.version_id).to eq(version1.id)
      end
    end

    context "when product has only one size and no other attributes (Base Model case)" do
      before do
        product.sizes << [size1]
      end

      it "builds one edition with no options" do
        product.build_new_editions
        expect(product.editions.size).to eq(1)
      end

      it "edition has no size, version, or color" do
        product.build_new_editions
        edition = product.editions.first
        expect(edition.size_id).to be_nil
        expect(edition.version_id).to be_nil
        expect(edition.color_id).to be_nil
      end
    end

    context "when product has one size and one version" do
      before do
        product.sizes << [size1]
        product.versions << [version1]
      end

      it "builds editions without size (single size is skipped)" do
        product.build_new_editions
        expect(product.editions.size).to eq(1) # 1 version, no size
      end

      it "does not include size in edition attributes" do
        product.build_new_editions
        expect(product.editions.first.size_id).to be_nil
        expect(product.editions.first.version_id).to eq(version1.id)
      end
    end

    context "when product attributes are removed" do
      before do
        product.sizes << [size1, size2]
        product.versions << [version1, version2]
        product.colors << [color1, color2]
        product.build_new_editions
        product.save
      end

      it "does not remove editions when size is removed (editions coexist with selectors)" do
        product.sizes.delete(size1)
        product.build_new_editions
        expect(product.editions.count(&:marked_for_destruction?)).to eq(0)
      end

      it "does not remove editions when version is removed (editions coexist with selectors)" do
        product.versions.delete(version1)
        product.build_new_editions
        expect(product.editions.count(&:marked_for_destruction?)).to eq(0)
      end

      it "does not remove editions when color is removed (editions coexist with selectors)" do
        product.colors.delete(color1)
        product.build_new_editions
        expect(product.editions.count(&:marked_for_destruction?)).to eq(0)
      end

      it "keeps all existing editions when removing attributes" do
        initial_editions_count = product.editions.count
        product.colors.delete(color1)
        product.build_new_editions
        expect(product.editions.count).to eq(initial_editions_count)
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

  describe "store_infos associations" do
    it "has many store_infos" do
      product = create(:product)
      shopify_info = product.store_infos.shopify.first
      woo_info = product.store_infos.woo.first

      expect(product.store_infos).to include(shopify_info, woo_info)
    end

    it "has one shopify_info" do
      product = create(:product)
      shopify_info = product.store_infos.shopify.first

      expect(product.shopify_info).to eq(shopify_info)
      expect(product.shopify_info.store_name).to eq("shopify")
    end

    it "has one woo_info" do
      product = create(:product)
      woo_info = product.store_infos.woo.first

      expect(product.woo_info).to eq(woo_info)
      expect(product.woo_info.store_name).to eq("woo")
    end

    it "destroys store_infos when product is destroyed" do
      product = create(:product)
      shopify_info_id = product.shopify_info.id
      woo_info_id = product.woo_info.id

      expect {
        product.destroy
      }.to change(StoreInfo, :count).by(-2)

      expect(StoreInfo.find_by(id: shopify_info_id)).to be_nil
      expect(StoreInfo.find_by(id: woo_info_id)).to be_nil
    end
  end

  describe "store_infos scoping" do
    it "returns shopify store_info through shopify_info association" do
      product = create(:product)

      expect(product.shopify_info).to be_a(StoreInfo)
      expect(product.shopify_info.store_name).to eq("shopify")
    end

    it "returns woo store_info through woo_info association" do
      product = create(:product)

      expect(product.woo_info).to be_a(StoreInfo)
      expect(product.woo_info.store_name).to eq("woo")
    end

    it "returns nil for shopify_info when not present" do
      product = create(:product)
      product.shopify_info.destroy

      expect(product.reload.shopify_info).to be_nil
    end

    it "returns nil for woo_info when not present" do
      product = create(:product)
      product.woo_info.destroy

      expect(product.reload.woo_info).to be_nil
    end
  end

  describe "store_infos uniqueness validation" do
    it "prevents duplicate store_name for the same product" do
      product = create(:product)

      expect {
        create(:store_info, :shopify, storable: product)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "allows same store_name for different products" do
      create(:product)
      product2 = create(:product)

      # Remove existing shopify store_info from product2 created by factory
      product2.store_infos.shopify.destroy_all

      expect {
        create(:store_info, :shopify, storable: product2)
      }.not_to raise_error
    end
  end
end
