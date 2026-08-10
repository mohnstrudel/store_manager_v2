# frozen_string_literal: true

require "rails_helper"

RSpec.describe Media::LegacyAttachmentBackfill do
  def uploaded_blob
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("legacy image data"),
      filename: "legacy.jpg",
      content_type: "image/jpeg"
    )
  end

  def legacy_attachment(record, blob: uploaded_blob)
    ActiveStorage::Attachment.create!(name: "images", record:, blob:)
  end

  describe ".call" do
    it "creates Media for a product with legacy images and no Media" do
      product = create(:product)
      blob_a = uploaded_blob
      blob_b = uploaded_blob
      legacy_attachment(product, blob: blob_a)
      legacy_attachment(product, blob: blob_b)

      result = described_class.call

      expect(result.created_count).to eq(2)
      expect(result.owners_backfilled).to eq(1)
      expect(product.media.ordered.map { |m| m.image.blob }).to eq([blob_a, blob_b])
      expect(product.media.ordered.map(&:position)).to eq([0, 1])
    end

    it "skips owners that already have image-bearing Media" do
      product = create(:product)
      existing_media = create(:media, :for_product, mediaable: product)
      legacy_attachment(product)

      result = described_class.call

      expect(result.created_count).to eq(0)
      expect(product.media.reload).to eq([existing_media])
    end

    it "treats a Media row with no attached image as still needing backfill" do
      product = create(:product)
      product.media.create!(position: 0)
      legacy_attachment(product)

      result = described_class.call

      expect(result.created_count).to eq(1)
      expect(product.media.count).to eq(2)
    end

    it "backfills warehouses the same way as products" do
      warehouse = create(:warehouse)
      legacy_attachment(warehouse)

      result = described_class.call

      expect(result.created_count).to eq(1)
      expect(warehouse.media.count).to eq(1)
    end

    it "is idempotent" do
      product = create(:product)
      legacy_attachment(product)

      described_class.call
      result = described_class.call

      expect(result.created_count).to eq(0)
      expect(product.media.count).to eq(1)
    end

    it "does not touch owners with no legacy attachment" do
      create(:product)

      result = described_class.call

      expect(result.created_count).to eq(0)
      expect(result.owners_backfilled).to eq(0)
    end
  end
end
