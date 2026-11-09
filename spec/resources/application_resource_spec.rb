# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationResource do
  it "builds Active Storage representation paths without a request host" do
    product = create(:product)
    create(:media, mediaable: product)
    sale_item = create(:sale_item, product: product.reload)

    thumb_url = Sales::ListingItemResource.new(sale_item).serializable_hash["product_thumb_url"]

    expect(thumb_url).to start_with("/rails/active_storage/representations/")
  end
end
