# frozen_string_literal: true

module Storage
  class BucketOrphanAudit
    Result = Data.define(:orphan_keys, :count, :total_bytes)

    def self.call(bucket: ActiveStorage::Blob.service.bucket)
      new(bucket:).call
    end

    def initialize(bucket:)
      @bucket = bucket
    end

    def call
      known_keys = ActiveStorage::Blob.pluck(:key).to_set
      orphan_keys = []
      total_bytes = 0

      bucket.objects.each do |object|
        next if known_keys.include?(object.key)

        orphan_keys << object.key
        total_bytes += object.size
      end

      Result.new(orphan_keys:, count: orphan_keys.size, total_bytes:)
    end

    private

    attr_reader :bucket
  end
end
