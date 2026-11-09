# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/MultipleExpectations
RSpec.describe ProductTitlePart do
  describe "franchise" do
    it "updates product full titles when franchise title changes" do
      franchise = create(:franchise, title: "Initial Franchise")
      product = create(:product, franchise:, title: "Hero Figure")
      old_full_title = product.reload.full_title

      franchise.update!(title: "Updated Franchise")

      expect(product.reload.full_title).to include("Updated Franchise")
      expect(product.reload.full_title).not_to eq(old_full_title)
    end
  end

  describe "product brand" do
    it "updates product full title when brand is attached" do
      product = create(:product, title: "Eva Figure")
      brand = create(:brand, title: "Kotobukiya")
      old_full_title = product.reload.full_title

      create(:product_brand, product:, brand:)

      expect(product.reload.full_title).to include("Kotobukiya")
      expect(product.reload.full_title).not_to eq(old_full_title)
    end
  end

  describe "brand" do
    it "updates product full titles when brand title changes" do
      brand = create(:brand, title: "Initial Brand")
      product = create(:product, title: "Hero Figure")
      create(:product_brand, product:, brand:)
      old_full_title = product.reload.full_title

      brand.update!(title: "Updated Brand")

      expect(product.reload.full_title).to include("Updated Brand")
      expect(product.reload.full_title).not_to eq(old_full_title)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
