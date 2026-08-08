# frozen_string_literal: true

require "rails_helper"

RSpec.describe Storage::ReclaimUnattachedBlobsJob do
  include ActiveJob::TestHelper

  def create_unattached_blob(created_at:)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("orphan blob data"),
      filename: "orphan.jpg",
      content_type: "image/jpeg"
    )
    blob.update_column(:created_at, created_at)
    blob
  end

  describe "#perform" do
    context "when delete_files is true" do
      before do
        allow(Rails.configuration.x.storage).to receive(:delete_files).and_return(true)
      end

      it "purges an unattached blob older than the grace period" do
        blob = create_unattached_blob(created_at: 3.days.ago)
        service = blob.service
        key = blob.key

        perform_enqueued_jobs do
          described_class.new.perform
        end

        expect(ActiveStorage::Blob.exists?(blob.id)).to be false
        expect(service.exist?(key)).to be false
      end

      it "leaves an unattached blob created inside the grace period untouched" do
        blob = create_unattached_blob(created_at: 1.hour.ago)

        perform_enqueued_jobs do
          described_class.new.perform
        end

        expect(ActiveStorage::Blob.exists?(blob.id)).to be true
        expect(blob.service.exist?(blob.key)).to be true
      end

      it "never purges a blob with a live attachment, regardless of age" do
        media = create(:media, :for_product)
        blob = media.image.blob
        blob.update_column(:created_at, 3.days.ago)

        perform_enqueued_jobs do
          described_class.new.perform
        end

        expect(ActiveStorage::Blob.exists?(blob.id)).to be true
        expect(blob.service.exist?(blob.key)).to be true
      end

      it "removes VariantRecords and their files when purging an unattached original" do
        blob = create_unattached_blob(created_at: 3.days.ago)
        variant_record = blob.variant_records.create!(variation_digest: "digest")
        variant_record.image.attach(
          io: StringIO.new("variant data"),
          filename: "thumb.webp",
          content_type: "image/webp"
        )
        variant_blob = variant_record.image.blob
        variant_service = variant_blob.service
        variant_key = variant_blob.key

        perform_enqueued_jobs do
          described_class.new.perform
        end

        expect(ActiveStorage::VariantRecord.exists?(variant_record.id)).to be false
        expect(ActiveStorage::Blob.exists?(variant_blob.id)).to be false
        expect(variant_service.exist?(variant_key)).to be false
      end

      it "logs the number of blobs it enqueued" do
        create_unattached_blob(created_at: 3.days.ago)
        create_unattached_blob(created_at: 3.days.ago)
        allow(Rails.logger).to receive(:info)

        described_class.new.perform

        expect(Rails.logger).to have_received(:info).with(
          "[Storage::ReclaimUnattachedBlobsJob] Enqueued 2 unattached blob(s) for purge"
        )
      end
    end

    context "when delete_files is false" do
      before do
        allow(Rails.configuration.x.storage).to receive(:delete_files).and_return(false)
      end

      it "leaves an unattached blob older than the grace period untouched and enqueues no PurgeJob" do
        blob = create_unattached_blob(created_at: 3.days.ago)

        expect {
          described_class.new.perform
        }.not_to have_enqueued_job(ActiveStorage::PurgeJob)

        expect(ActiveStorage::Blob.exists?(blob.id)).to be true
        expect(blob.service.exist?(blob.key)).to be true
      end

      it "leaves an unattached blob created inside the grace period untouched" do
        blob = create_unattached_blob(created_at: 1.hour.ago)

        expect {
          described_class.new.perform
        }.not_to have_enqueued_job(ActiveStorage::PurgeJob)

        expect(ActiveStorage::Blob.exists?(blob.id)).to be true
      end
    end
  end
end
