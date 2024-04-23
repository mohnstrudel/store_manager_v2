# == Schema Information
#
# Table name: variations
#
#  id         :bigint           not null, primary key
#  store_link :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color_id   :bigint
#  product_id :bigint           not null
#  size_id    :bigint
#  version_id :bigint
#  woo_id     :string
#
require "rails_helper"

RSpec.describe Variation do
  describe "#title" do
    context "when variation has sizes" do
      sizes = ["1:4", "1:6"]
      let(:variation_one)	{ create(:variation, :with_size, size_value: sizes.first) }
      let(:variation_two)	{ create(:variation, :with_size, size_value: sizes.last) }

      it "title includes #{sizes.first}" do
        expect(variation_one.title).to include(sizes.first)
      end

      it "title includes #{sizes.last}" do
        expect(variation_two.title).to include(sizes.last)
      end
    end

    context "when variation has versions" do
      versions = ["Regular Armor", "Revealing Armor"]
      let(:variation_one)	{ create(:variation, :with_version, version_value: versions.first) }
      let(:variation_two)	{ create(:variation, :with_version, version_value: versions.last) }

      it "title includes #{versions.first}" do
        expect(variation_one.title).to include(versions.first)
      end

      it "title includes #{versions.last}" do
        expect(variation_two.title).to include(versions.last)
      end
    end

    context "when variation has colors" do
      colors = ["Blau", "Grau"]
      let(:variation_one)	{ create(:variation, :with_color, color_value: colors.first) }
      let(:variation_two)	{ create(:variation, :with_color, color_value: colors.last) }

      it "title includes #{colors.first}" do
        expect(variation_one.title).to include(colors.first)
      end

      it "title includes #{colors.last}" do
        expect(variation_two.title).to include(colors.last)
      end
    end
  end
end
