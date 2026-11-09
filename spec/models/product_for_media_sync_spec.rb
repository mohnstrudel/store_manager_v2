# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe ".with_media_and_shopify_info" do
    it "loads media and its Shopify references for sync work" do
      product = create(:product)
      create(:media, :for_product, mediaable: product)

      records = described_class.with_media_and_shopify_info.where(id: product.id).to_a

      aggregate_failures do
        expect(records).to include(product)
        expect(records.first.association(:media).loaded?).to be true
        expect(records.first.media.first.association(:image_attachment).loaded?).to be true
        expect(records.first.media.first.association(:image_blob).loaded?).to be true
      end
    end
  end
end
