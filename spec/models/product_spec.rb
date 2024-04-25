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
end
