# frozen_string_literal: true

require "rails_helper"

RSpec.describe Storage::LegacyImageAttachmentCleanup do
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
    it "raises NotPermitted when config.x.storage.delete_files is false" do
      allow(Rails.configuration.x.storage).to receive(:delete_files).and_return(false)

      expect { described_class.call }.to raise_error(described_class::NotPermitted)
    end

    it "raises Blocked and deletes nothing when an owner has no covering Media" do
      product = create(:product)
      legacy_attachment(product)

      expect {
        expect { described_class.call }.to raise_error(described_class::Blocked)
      }.not_to change(ActiveStorage::Attachment, :count)
    end

    it "does not touch the owner's updated_at" do
      product = create(:product)
      media = create(:media, :for_product, mediaable: product)
      legacy_attachment(product, blob: media.image.blob)

      expect { described_class.call(scope: :retained) }.not_to(change { product.reload.updated_at })
    end

    describe "scope: :retained" do
      it "deletes only retained rows and purges nothing" do
        product = create(:product)
        media = create(:media, :for_product, mediaable: product)
        retained = legacy_attachment(product, blob: media.image.blob)
        releasing = legacy_attachment(product)

        result = nil
        expect {
          result = described_class.call(scope: :retained)
        }.not_to have_enqueued_job(ActiveStorage::PurgeJob)

        expect(result.deleted_count).to eq(1)
        expect(result.released_blob_count).to eq(0)
        expect(ActiveStorage::Attachment.exists?(retained.id)).to be false
        expect(ActiveStorage::Attachment.exists?(releasing.id)).to be true
      end
    end

    describe "scope: :all" do
      it "deletes retained and releasing rows, purging exactly the released blobs" do
        product = create(:product)
        media = create(:media, :for_product, mediaable: product)
        retained = legacy_attachment(product, blob: media.image.blob)
        releasing_blob = uploaded_blob
        releasing = legacy_attachment(product, blob: releasing_blob)

        result = nil
        expect {
          result = described_class.call(scope: :all)
        }.to have_enqueued_job(ActiveStorage::PurgeJob).exactly(1).times

        expect(result.deleted_count).to eq(2)
        expect(result.released_blob_count).to eq(1)
        expect(result.released_bytes).to eq(releasing_blob.byte_size)
        expect(ActiveStorage::Attachment.exists?(retained.id)).to be false
        expect(ActiveStorage::Attachment.exists?(releasing.id)).to be false
      end

      it "does not delete releasing_unrecoverable rows by default" do
        product = create(:product)
        product.shopify_info.destroy
        create(:media, :for_product, mediaable: product)
        unrecoverable = legacy_attachment(product)

        result = described_class.call(scope: :all)

        expect(result.deleted_count).to eq(0)
        expect(ActiveStorage::Attachment.exists?(unrecoverable.id)).to be true
      end

      it "deletes releasing_unrecoverable rows when allow_unrecoverable: true" do
        product = create(:product)
        product.shopify_info.destroy
        create(:media, :for_product, mediaable: product)
        unrecoverable = legacy_attachment(product)

        expect {
          described_class.call(scope: :all, allow_unrecoverable: true)
        }.to have_enqueued_job(ActiveStorage::PurgeJob).exactly(1).times

        expect(ActiveStorage::Attachment.exists?(unrecoverable.id)).to be false
      end
    end
  end
end
