# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorage::Blob::Reclamation do
  let(:stored_object_class) { Data.define(:key, :size, :last_modified) }
  let(:delete_error_class) { Data.define(:key, :message) }
  let(:delete_response_class) { Data.define(:errors) }
  let(:service_class) { Data.define(:name, :bucket) }
  let(:bucket_class) do
    response_class = delete_response_class

    Class.new do
      attr_accessor :delete_error, :delete_errors
      attr_reader :deleted_keys, :objects

      define_method(:initialize) do |objects|
        @objects = objects
        @deleted_keys = []
        @delete_errors = []
      end

      define_method(:delete_objects) do |delete:|
        raise delete_error if delete_error

        keys = delete.fetch(:objects).map { |object| object.fetch(:key) }
        failed_keys = delete_errors.map(&:key)
        successful_keys = keys - failed_keys
        deleted_keys.concat(successful_keys)
        objects.reject! { |object| successful_keys.include?(object.key) }
        response_class.new(errors: delete_errors)
      end
    end
  end
  let(:objects) { [] }
  let(:bucket) { bucket_class.new(objects) }
  let(:service) { service_class.new(name: "test", bucket:) }
  let(:cutoff) { 30.days.ago }

  def create_blob(key:, created_at: 31.days.ago)
    ActiveStorage::Blob.create!(
      key:,
      filename: "image.jpg",
      content_type: "image/jpeg",
      byte_size: 1,
      checksum: Base64.strict_encode64(Digest::MD5.digest(key)),
      service_name: "test",
      created_at:
    )
  end

  def stored_object(key, size:, last_modified: 31.days.ago)
    stored_object_class.new(key:, size:, last_modified:)
  end

  describe ".enqueue!" do
    it "queues the retryable transport job with a stable cutoff" do
      expect { described_class.enqueue!(cutoff:) }
        .to have_enqueued_job(ActiveStorage::Blob::ReclamationJob).with(cutoff: cutoff.iso8601)
    end

    it "raises when the transport job cannot be enqueued" do
      job = instance_double(ActiveStorage::Blob::ReclamationJob, successfully_enqueued?: false)
      allow(ActiveStorage::Blob::ReclamationJob).to receive(:perform_later).and_return(job)

      expect { described_class.enqueue!(cutoff:) }.to raise_error(described_class::EnqueueFailed)
    end
  end

  it "deletes only objects classified as safely reclaimable", :aggregate_failures do
    blob = create_blob(key: "a" * 28)
    objects.concat([
      stored_object(blob.key, size: 100),
      stored_object("variants/#{blob.key}/digest", size: 10),
      stored_object("b" * 28, size: 200),
      stored_object("unmanaged.jpg", size: 400),
      stored_object("c" * 28, size: 800, last_modified: 1.day.ago)
    ])

    result = described_class.apply!(cutoff:, service:)

    expect(result.to_h).to eq(deleted_object_count: 3, deleted_bytes: 310)
    expect(bucket.deleted_keys).to contain_exactly(blob.key, "variants/#{blob.key}/digest", "b" * 28)
    expect(ActiveStorage::Blob.exists?(blob.id)).to be false
    expect(objects.map(&:key)).to contain_exactly("unmanaged.jpg", "c" * 28)
  end

  it "revalidates database ownership before deleting a previously selected object" do
    blob = create_blob(key: "a" * 28)
    object = stored_object(blob.key, size: 100)
    objects << object
    candidate = ActiveStorage::Blob::ReclaimableSpace::Candidate.new(
      key: blob.key,
      size: object.size,
      parent_key: blob.key
    )
    scanner = instance_double(ActiveStorage::Blob::ReclaimableSpace)
    allow(scanner).to receive(:each_reclaimable_batch).and_yield([candidate])
    allow(ActiveStorage::Blob::ReclaimableSpace).to receive(:new).and_return(scanner)
    create(:attachment, blob:, record: create(:product))

    result = described_class.apply!(cutoff:, service:)

    expect(result.to_h).to eq(deleted_object_count: 0, deleted_bytes: 0)
    expect(bucket.deleted_keys).to be_empty
    expect(ActiveStorage::Blob.exists?(blob.id)).to be true
  end

  it "retries safely after releasing a blob but failing to delete its object" do
    blob = create_blob(key: "a" * 28)
    objects << stored_object(blob.key, size: 100)
    bucket.delete_error = IOError.new("R2 unavailable")

    expect { described_class.apply!(cutoff:, service:) }.to raise_error(IOError, "R2 unavailable")
    expect(ActiveStorage::Blob.exists?(blob.id)).to be false
    expect(objects.map(&:key)).to include(blob.key)

    bucket.delete_error = nil

    expect(described_class.apply!(cutoff:, service:).deleted_bytes).to eq(100)
    expect(objects).to be_empty
  end

  it "raises when R2 reports a failed key in a bulk deletion" do
    key = "a" * 28
    objects << stored_object(key, size: 100)
    bucket.delete_errors = [delete_error_class.new(key:, message: "access denied")]

    expect { described_class.apply!(cutoff:, service:) }
      .to raise_error(described_class::DeleteFailed, /#{key}: access denied/)
    expect(objects.map(&:key)).to contain_exactly(key)
  end

  it "is harmless when repeated after all reclaimable objects were deleted" do
    objects << stored_object("a" * 28, size: 100)

    described_class.apply!(cutoff:, service:)

    expect(described_class.apply!(cutoff:, service:).to_h)
      .to eq(deleted_object_count: 0, deleted_bytes: 0)
  end
end
