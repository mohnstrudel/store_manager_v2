# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorage::Blob::ReclaimableSpace do
  let(:stored_object_class) { Data.define(:key, :size, :last_modified) }
  let(:bucket_class) { Data.define(:objects) }
  let(:service_class) { Data.define(:name, :bucket) }
  let(:service_name) { "test" }

  def create_blob(key:, service_name: "test", created_at: Time.current)
    ActiveStorage::Blob.create!(
      key:,
      filename: "image.jpg",
      content_type: "image/jpeg",
      byte_size: 1,
      checksum: Base64.strict_encode64(Digest::MD5.digest(key)),
      service_name:,
      created_at:
    )
  end

  def stored_object(key, size:, last_modified: 31.days.ago)
    stored_object_class.new(key:, size:, last_modified:)
  end

  def reclaimable_bytes(objects, cutoff: 30.days.ago)
    described_class.bytes(
      cutoff:,
      service: service_class.new(name: service_name, bucket: bucket_class.new(objects:))
    )
  end

  describe ".bytes" do
    it "counts only conservatively reclaimable objects", :aggregate_failures do
      attached_key = "a" * 28
      unattached_key = "b" * 28
      recent_unattached_key = "c" * 28
      orphan_key = "d" * 28
      orphan_variant_key = "e" * 28
      attached_blob = create_blob(key: attached_key, created_at: 31.days.ago)
      create_blob(key: unattached_key, created_at: 31.days.ago)
      create_blob(key: recent_unattached_key, created_at: 1.day.ago)
      create(:attachment, blob: attached_blob, record: create(:product))
      objects = [
        stored_object(attached_key, size: 100),
        stored_object("variants/#{attached_key}/digest", size: 10),
        stored_object(unattached_key, size: 200),
        stored_object("variants/#{unattached_key}/digest", size: 20),
        stored_object(recent_unattached_key, size: 300),
        stored_object(orphan_key, size: 400),
        stored_object("variants/#{orphan_variant_key}/digest", size: 40),
        stored_object("unmanaged-file.jpg", size: 500),
        stored_object("f" * 28, size: 600, last_modified: 1.day.ago)
      ]

      expect {
        result = reclaimable_bytes(objects)

        expect(result).to eq(660)
      }.not_to change { [ActiveStorage::Blob.count, ActiveStorage::Attachment.count] }
    end

    it "does not count an object whose blob belongs to another service" do
      key = "a" * 28
      create_blob(key:, service_name: "local", created_at: 31.days.ago)

      expect(reclaimable_bytes([stored_object(key, size: 10)])).to eq(0)
    end

    it "does not count malformed variant paths" do
      objects = [
        stored_object("variants/#{"a" * 28}", size: 10),
        stored_object("variants//digest", size: 10)
      ]

      expect(reclaimable_bytes(objects)).to eq(0)
    end

    it "processes object listings in bounded database lookup batches" do
      objects = Array.new(described_class::BATCH_SIZE + 1) do |index|
        key = index.to_s(36).rjust(28, "0")
        stored_object(key, size: 1)
      end

      expect(reclaimable_bytes(objects)).to eq(1_001)
    end

    it "rejects services that cannot list their objects" do
      expect {
        described_class.bytes(service: Object.new)
      }.to raise_error(described_class::UnsupportedService)
    end
  end
end
