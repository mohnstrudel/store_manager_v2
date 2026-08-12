# frozen_string_literal: true

require "rails_helper"

RSpec.describe Media::LegacyAttachments::Cleanup do
  def uploaded_blob(contents = "legacy image data")
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(contents),
      filename: "legacy.jpg",
      content_type: "image/jpeg"
    )
  end

  def legacy_attachment(record, blob: uploaded_blob)
    ActiveStorage::Attachment.create!(name: Media::LegacyAttachments::NAME, record:, blob:)
  end

  describe ".enqueue!" do
    it "returns zeroed counts when there are no legacy attachments" do
      result = described_class.enqueue!

      expect(result.to_h).to eq(
        queued_batch_count: 0,
        scheduled_attachment_count: 0,
        purge_candidate_count: 0,
        purge_candidate_bytes: 0,
        unrecoverable_count: 0
      )
    end

    it "blocks all scheduling when an owner has no image-bearing Media" do
      product = create(:product)
      legacy_attachment(product)

      expect {
        expect { described_class.enqueue! }.to raise_error(described_class::Blocked)
      }.not_to have_enqueued_job(Media::LegacyAttachments::CleanupJob)
    end

    it "blocks all scheduling when an owner has partial legacy blob coverage" do
      product = create(:product)
      covered_blob = uploaded_blob("covered")
      legacy_attachment(product, blob: covered_blob)
      legacy_attachment(product, blob: uploaded_blob("missing"))
      product.media.create!(image: covered_blob)

      expect {
        expect { described_class.enqueue! }.to raise_error(described_class::Blocked)
      }.not_to have_enqueued_job(Media::LegacyAttachments::CleanupJob)
    end

    it "queues a retained row without a purge candidate" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product)
      retained = legacy_attachment(product, blob: media.image.blob)

      result = described_class.enqueue!

      expect(Media::LegacyAttachments::CleanupJob).to have_been_enqueued.with(
        owner_type: "Product",
        attachment_ids: [retained.id],
        purge_blob_ids: []
      )
      expect(result.scheduled_attachment_count).to eq(1)
      expect(result.purge_candidate_count).to eq(0)
      expect(ActiveStorage::Attachment.exists?(retained.id)).to be true
    end

    it "queues a unique Shopify-recoverable row with its stable purge candidate", :aggregate_failures do
      product = create(:product)
      create(:media, :for_product, mediaable: product)
      releasing_blob = uploaded_blob
      releasing = legacy_attachment(product, blob: releasing_blob)

      result = described_class.enqueue!

      expect(Media::LegacyAttachments::CleanupJob).to have_been_enqueued.with(
        owner_type: "Product",
        attachment_ids: [releasing.id],
        purge_blob_ids: [releasing_blob.id]
      )
      expect(result.purge_candidate_count).to eq(1)
      expect(result.purge_candidate_bytes).to eq(releasing_blob.byte_size)
    end

    it "leaves a unique row alone when its live owner is not recoverable" do
      product = create(:product)
      product.shopify_info.destroy!
      create(:media, :for_product, mediaable: product)
      unrecoverable = legacy_attachment(product)

      result = nil

      expect { result = described_class.enqueue! }
        .not_to have_enqueued_job(Media::LegacyAttachments::CleanupJob)

      expect(result.unrecoverable_count).to eq(1)
      expect(ActiveStorage::Attachment.exists?(unrecoverable.id)).to be true
    end

    it "treats PurchaseItem as a supported non-recoverable owner" do
      purchase_item = create(:purchase_item)
      create(:media, :for_purchase_item, mediaable: purchase_item)
      unrecoverable = legacy_attachment(purchase_item)

      result = described_class.enqueue!

      expect(result.unrecoverable_count).to eq(1)
      expect(ActiveStorage::Attachment.exists?(unrecoverable.id)).to be true
    end

    it "queues an orphan row for deletion and purge" do
      product = create(:product)
      orphaned_blob = uploaded_blob
      orphaned = legacy_attachment(product, blob: orphaned_blob)
      product.destroy!

      result = described_class.enqueue!

      expect(Media::LegacyAttachments::CleanupJob).to have_been_enqueued.with(
        owner_type: "Product",
        attachment_ids: [orphaned.id],
        purge_blob_ids: [orphaned_blob.id]
      )
      expect(result.purge_candidate_count).to eq(1)
    end

    it "queues an orphan row without purge when another attachment retains its blob" do
      product = create(:product)
      other_media = create(:media, :for_product)
      orphaned = legacy_attachment(product, blob: other_media.image.blob)
      product.destroy!

      described_class.enqueue!

      expect(Media::LegacyAttachments::CleanupJob).to have_been_enqueued.with(
        owner_type: "Product",
        attachment_ids: [orphaned.id],
        purge_blob_ids: []
      )
    end

    it "does not touch the owner's updated_at" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product)
      legacy_attachment(product, blob: media.image.blob)

      expect { described_class.enqueue! }.not_to(change { product.reload.updated_at })
    end
  end
end
