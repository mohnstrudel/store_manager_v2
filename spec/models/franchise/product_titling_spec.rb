# frozen_string_literal: true

require "rails_helper"

# rubocop:todo RSpec/MultipleExpectations
RSpec.describe Franchise::ProductTitling do
  describe "product title synchronization" do
    it "updates product full titles when franchise title changes" do
      franchise = create(:franchise, title: "Initial Franchise")
      product = create(:product, franchise:, title: "Hero Figure")
      old_full_title = product.reload.full_title

      franchise.update!(title: "Updated Franchise")

      expect(product.reload.full_title).to include("Updated Franchise")
      expect(product.reload.full_title).not_to eq(old_full_title)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
