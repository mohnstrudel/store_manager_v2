# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push::Cleanup do
  let(:product) { create(:product) }
  let(:media) { create(:media, mediaable: product) }
  let(:other_media) { create(:media, mediaable: product) }
  let(:error) { StandardError.new(error_message) }

  before do
    media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/1")
    other_media.store_infos.create!(store_name: :shopify, store_id: "gid://shopify/MediaImage/2")
    other_media.store_infos.create!(store_name: :woo, store_id: "woo-media-2")
  end

  describe "#call" do
    context "when the error indicates the product is missing on Shopify" do
      let(:error_message) { "Failed to call the productUpdate API mutation: Product does not exist" }

      it "removes the product and associated Shopify media store infos" do
        expect {
          described_class.new(product:).call(error)
        }.to change { product.reload.shopify_info.present? }.from(true).to(false)

        expect(media.reload.store_infos.where(store_name: :shopify)).to be_empty
        expect(other_media.reload.store_infos.where(store_name: :shopify)).to be_empty
        expect(other_media.reload.store_infos.where(store_name: :woo)).to exist
      end
    end

    context "when the error is unrelated" do
      let(:error_message) { "Rate limit exceeded" }

      it "does nothing" do
        described_class.new(product:).call(error)

        expect(product.reload.shopify_info).to be_present
        expect(media.reload.store_infos.where(store_name: :shopify)).to be_present
        expect(other_media.reload.store_infos.where(store_name: :shopify)).to be_present
      end
    end
  end
end
