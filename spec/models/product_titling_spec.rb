# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#generate_full_title" do
    let(:franchise) { create(:franchise, title: "Elden Ring") }
    let(:brand) { create(:brand, title: "Coolbear Studio") }
    let(:brand2) { create(:brand, title: "Prime 1 Studio") }

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
end
