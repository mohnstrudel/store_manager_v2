# frozen_string_literal: true

require "rails_helper"

RSpec.describe Media::LegacyAttachments::CleanupJob do
  def uploaded_blob
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("legacy image data"),
      filename: "legacy.jpg",
      content_type: "image/jpeg"
    )
  end

  def legacy_attachment(record, blob: uploaded_blob)
    ActiveStorage::Attachment.create!(name: Media::LegacyAttachments::NAME, record:, blob:)
  end

  it "uses the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "deletes the selected safe attachments" do
    product = create(:product)
    media = create(:media, :for_product, mediaable: product)
    retained = legacy_attachment(product, blob: media.image.blob)

    expect {
      described_class.perform_now(owner_type: "Product", attachment_ids: [retained.id], purge_blob_ids: [])
    }.to change { ActiveStorage::Attachment.exists?(retained.id) }.from(true).to(false)
  end

  it "enqueues a purge for each stable blob ID after deleting the attachment" do
    product = create(:product)
    create(:media, :for_product, mediaable: product)
    releasing_blob = uploaded_blob
    releasing = legacy_attachment(product, blob: releasing_blob)

    expect {
      described_class.perform_now(
        owner_type: "Product",
        attachment_ids: [releasing.id],
        purge_blob_ids: [releasing_blob.id]
      )
    }.to have_enqueued_job(ActiveStorage::PurgeJob).with(releasing_blob)

    expect(ActiveStorage::Attachment.exists?(releasing.id)).to be false
  end

  it "retries purge enqueue from stable arguments after attachments were already deleted" do
    product = create(:product)
    create(:media, :for_product, mediaable: product)
    releasing_blob = uploaded_blob
    releasing = legacy_attachment(product, blob: releasing_blob)
    arguments = {
      owner_type: "Product",
      attachment_ids: [releasing.id],
      purge_blob_ids: [releasing_blob.id]
    }
    allow(ActiveStorage::PurgeJob).to receive(:perform_later).and_return(false)

    expect { described_class.perform_now(**arguments) }
      .to raise_error(Media::LegacyAttachments::Cleanup::EnqueueFailed)
    expect(ActiveStorage::Attachment.exists?(releasing.id)).to be false

    allow(ActiveStorage::PurgeJob).to receive(:perform_later).and_call_original

    expect { described_class.perform_now(**arguments) }
      .to have_enqueued_job(ActiveStorage::PurgeJob).with(releasing_blob)
  end

  it "is harmless when the same batch runs twice" do
    product = create(:product)
    media = create(:media, :for_product, mediaable: product)
    retained = legacy_attachment(product, blob: media.image.blob)
    arguments = {owner_type: "Product", attachment_ids: [retained.id], purge_blob_ids: []}

    described_class.perform_now(**arguments)

    expect { described_class.perform_now(**arguments) }.not_to raise_error
  end

  it "ignores a purge candidate that has already been removed" do
    missing_blob_id = ActiveStorage::Blob.maximum(:id).to_i + 1

    expect {
      described_class.perform_now(owner_type: "Product", attachment_ids: [], purge_blob_ids: [missing_blob_id])
    }.not_to raise_error
  end

  it "revalidates safety before deleting a queued attachment" do
    product = create(:product)
    media = create(:media, :for_product, mediaable: product)
    legacy = legacy_attachment(product)
    media.destroy!

    expect {
      described_class.perform_now(owner_type: "Product", attachment_ids: [legacy.id], purge_blob_ids: [])
    }.to raise_error(Media::LegacyAttachments::Cleanup::Blocked)
    expect(ActiveStorage::Attachment.exists?(legacy.id)).to be true
  end

  it "does not purge when another attachment starts retaining the blob" do
    product = create(:product)
    create(:media, :for_product, mediaable: product)
    releasing_blob = uploaded_blob
    releasing = legacy_attachment(product, blob: releasing_blob)
    retaining_media = build(:media, :for_product)
    retaining_media.image.attach(releasing_blob)
    retaining_media.save!

    expect {
      described_class.perform_now(
        owner_type: "Product",
        attachment_ids: [releasing.id],
        purge_blob_ids: [releasing_blob.id]
      )
    }.to raise_error(Media::LegacyAttachments::Cleanup::Blocked)
    expect(ActiveStorage::Attachment.exists?(releasing.id)).to be true
  end
end
