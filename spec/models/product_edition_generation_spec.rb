# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
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

      it "builds editions for each version" do
        product.build_new_editions
        expect(product.editions.size).to eq(1)
      end
    end

    context "when product has only colors" do
      before do
        product.colors << [color1, color2]
      end

      it "builds editions for each color" do
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
        aggregate_failures do
          expect(product.editions.size).to eq(1)
          expect(product.editions.first.color_id).to eq(color1.id)
        end
      end
    end

    context "when product has only one version and no other attributes" do
      before do
        product.versions << [version1]
      end

      it "builds one edition with the version" do
        product.build_new_editions
        aggregate_failures do
          expect(product.editions.size).to eq(1)
          expect(product.editions.first.version_id).to eq(version1.id)
        end
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

        aggregate_failures do
          expect(edition.size_id).to be_nil
          expect(edition.version_id).to be_nil
          expect(edition.color_id).to be_nil
        end
      end
    end
  end

  describe "#fetch_editions_with_title" do
    let(:product) { create(:product) }
    let!(:titled_edition) { create(:edition, product:) }

    it "returns editions with their option associations preloaded" do
      result = product.fetch_editions_with_title

      aggregate_failures do
        expect(result).to contain_exactly(titled_edition)
        expect(result.first.association(:version).loaded?).to be true
        expect(result.first.association(:color).loaded?).to be true
        expect(result.first.association(:size).loaded?).to be true
      end
    end
  end
end
