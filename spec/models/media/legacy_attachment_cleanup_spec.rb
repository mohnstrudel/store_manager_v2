# frozen_string_literal: true

require "rails_helper"

RSpec.describe Media::LegacyAttachmentCleanup do
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
    it "returns zeroed counts when there are no legacy attachments" do
      result = described_class.call

      expect(result.deleted_count).to eq(0)
    end

    it "raises Blocked and deletes nothing when an owner has no covering Media" do
      product = create(:product)
      legacy_attachment(product)

      expect {
        expect { described_class.call }.to raise_error(described_class::Blocked)
      }.not_to change(ActiveStorage::Attachment, :count)
    end

    it "raises Blocked when the owner's only Media has no attached image" do
      product = create(:product)
      product.media.create!(position: 0)
      legacy_attachment(product)

      expect { described_class.call }.to raise_error(described_class::Blocked)
    end

    it "deletes a row whose blob is retained elsewhere without purging anything" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product)
      retained = legacy_attachment(product, blob: media.image.blob)

      result = nil
      expect {
        result = described_class.call
      }.not_to have_enqueued_job(ActiveStorage::PurgeJob)

      expect(result.deleted_count).to eq(1)
      expect(result.released_blob_count).to eq(0)
      expect(ActiveStorage::Attachment.exists?(retained.id)).to be false
    end

    it "keeps a row retained when its blob is attached as Media#image on a different record" do
      owner = create(:product)
      create(:media, :for_product, mediaable: owner)
      other_media = create(:media, :for_product, mediaable: create(:product))
      shared_blob = uploaded_blob
      other_media.image.attach(shared_blob)
      shared = legacy_attachment(owner, blob: shared_blob)

      expect {
        described_class.call
      }.not_to have_enqueued_job(ActiveStorage::PurgeJob)

      expect(ActiveStorage::Attachment.exists?(shared.id)).to be false
    end

    it "deletes and purges a releasing row when the owner is Shopify-linked" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product)
      releasing_blob = uploaded_blob
      releasing = legacy_attachment(product, blob: releasing_blob)

      result = nil
      expect {
        result = described_class.call
      }.to have_enqueued_job(ActiveStorage::PurgeJob).exactly(1).times

      expect(media).to be_present
      expect(result.deleted_count).to eq(1)
      expect(result.released_blob_count).to eq(1)
      expect(result.released_bytes).to eq(releasing_blob.byte_size)
      expect(ActiveStorage::Attachment.exists?(releasing.id)).to be false
    end

    it "leaves a releasing row alone when the owner has no Shopify link, and reports it" do
      product = create(:product)
      product.shopify_info.destroy
      create(:media, :for_product, mediaable: product)
      unrecoverable = legacy_attachment(product)

      result = described_class.call

      expect(result.deleted_count).to eq(0)
      expect(result.unrecoverable_count).to eq(1)
      expect(ActiveStorage::Attachment.exists?(unrecoverable.id)).to be true
    end

    it "classifies a Warehouse legacy row the same way as Product" do
      warehouse = create(:warehouse)
      create(:media, :for_warehouse, mediaable: warehouse)
      unrecoverable = legacy_attachment(warehouse)

      result = described_class.call

      expect(result.unrecoverable_count).to eq(1)
      expect(ActiveStorage::Attachment.exists?(unrecoverable.id)).to be true
    end

    it "deletes and purges a row whose owner record no longer exists" do
      product = create(:product)
      orphaned = legacy_attachment(product)
      product.destroy

      expect {
        described_class.call
      }.to have_enqueued_job(ActiveStorage::PurgeJob).exactly(1).times

      expect(ActiveStorage::Attachment.exists?(orphaned.id)).to be false
    end

    it "does not touch the owner's updated_at" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product)
      legacy_attachment(product, blob: media.image.blob)

      expect { described_class.call }.not_to(change { product.reload.updated_at })
    end
  end
end
