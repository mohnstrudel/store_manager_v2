# frozen_string_literal: true

module Storage
  class LegacyImageAttachmentCleanup
    BATCH_SIZE = 1_000
    Blocked = Class.new(StandardError)
    Result = Data.define(:deleted_count, :released_blob_count, :released_bytes)

    def self.call(allow_unrecoverable: false, scope: :all)
      new(allow_unrecoverable:, scope:).call
    end

    def initialize(allow_unrecoverable: false, scope: :all)
      @allow_unrecoverable = allow_unrecoverable
      @scope = scope
    end

    def call
      audit = LegacyImageAttachmentAudit.call

      if audit.blocked?
        raise Blocked, "#{audit.blocked_ids.size} legacy attachment(s) on #{audit.blocked_owners.size} owner(s) with no covering Media"
      end

      delete_ids = scope == :retained ? audit.retained_ids : audit.deletable_ids(allow_unrecoverable:)
      released_ids = scope == :retained ? [] : audit.released_ids(allow_unrecoverable:)
      blob_ids = blob_ids_for(released_ids)
      released_bytes = bytes_for(blob_ids)

      deleted_count = delete_attachments(delete_ids)
      purge_blobs(blob_ids)

      Result.new(deleted_count:, released_blob_count: blob_ids.size, released_bytes:)
    end

    private

    attr_reader :allow_unrecoverable, :scope

    def blob_ids_for(attachment_ids)
      return [] if attachment_ids.empty?

      ActiveStorage::Attachment.where(id: attachment_ids).distinct.pluck(:blob_id)
    end

    def bytes_for(blob_ids)
      return 0 if blob_ids.empty?

      ActiveStorage::Blob.where(id: blob_ids).sum(:byte_size)
    end

    def delete_attachments(ids)
      return 0 if ids.empty?

      ActiveStorage::Attachment.where(id: ids).in_batches(of: BATCH_SIZE).delete_all
    end

    def purge_blobs(blob_ids)
      ActiveStorage::Blob.where(id: blob_ids).find_each(&:purge_later)
    end
  end
end
