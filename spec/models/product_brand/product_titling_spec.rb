# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/MultipleExpectations
RSpec.describe ProductBrand::ProductTitling do
  describe "product title synchronization" do
    it "updates product full title when brand is attached" do
      product = create(:product, title: "Eva Figure")
      brand = create(:brand, title: "Kotobukiya")
      old_full_title = product.reload.full_title

      create(:product_brand, product:, brand:)

      expect(product.reload.full_title).to include("Kotobukiya")
      expect(product.reload.full_title).not_to eq(old_full_title)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
