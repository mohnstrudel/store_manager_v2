# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchases::ListingResource do
  it "serves the product thumbnail path when the product has media" do
    product = create(:product)
    create(:media, :for_product, mediaable: product)
    purchase = create(:purchase, product:)

    props = described_class.new(purchase.reload).serializable_hash.deep_symbolize_keys

    expect(props[:product_thumb_url]).to start_with("/rails/active_storage/")
  end
end
