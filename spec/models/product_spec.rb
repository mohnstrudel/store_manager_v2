# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  full_title   :string
#  image        :string
#  sku          :string
#  slug         :string
#  store_link   :string
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

    context "when product is created" do
      it "composes full title like 'franchise.title — product.title | brand.title'" do
        product = create(:product_with_brands, title: "Malenia", franchise:, brand_title: brand.title)
        canonical_title = "#{franchise.title} — #{product.title} | #{brand.title}"

        expect(product.full_title).to eq(canonical_title)
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
end
