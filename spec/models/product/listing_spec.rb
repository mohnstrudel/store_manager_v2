# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe ".listed" do
    it "eager loads the listing associations and orders newest first" do
      older = create(:product)
      newer = create(:product)

      relation = described_class.listed.where(id: [older.id, newer.id]).to_a

      aggregate_failures do
        expect(relation.first.id).to eq(newer.id)
        expect(relation.first.association(:shopify_info).loaded?).to be true
        expect(relation.first.association(:woo_info).loaded?).to be true
        expect(relation.first.association(:editions).loaded?).to be true
      end
    end
  end

  describe ".for_details" do
    it "eager loads product detail associations" do
      product = create(:product)
      create(:purchase, product:)

      relation = described_class.for_details.where(id: product.id).to_a

      aggregate_failures do
        expect(relation).to include(product)
        expect(relation.first.association(:purchases).loaded?).to be true
        expect(relation.first.association(:purchase_items).loaded?).to be true
        expect(relation.first.association(:store_infos).loaded?).to be true
      end
    end
  end

  describe ".for_media_sync" do
    it "eager loads the media attachments for syncing" do
      product = create(:product)
      create(:media, :for_product, mediaable: product)

      relation = described_class.for_media_sync.where(id: product.id).to_a

      aggregate_failures do
        expect(relation).to include(product)
        expect(relation.first.association(:media).loaded?).to be true
        expect(relation.first.media.first.association(:image_attachment).loaded?).to be true
        expect(relation.first.media.first.association(:image_blob).loaded?).to be true
      end
    end
  end
end
