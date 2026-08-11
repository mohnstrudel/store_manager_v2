# frozen_string_literal: true

module Storage
  class LegacyImageAttachmentCleanup
    LEGACY_NAME = "images"
    BATCH_SIZE = 1_000
    Blocked = Class.new(StandardError)
    Result = Data.define(:deleted_count, :released_blob_count, :released_bytes, :unrecoverable_count)

    def self.call
      new.call
    end

    def call
      rows = legacy_rows
      return Result.new(deleted_count: 0, released_blob_count: 0, released_bytes: 0, unrecoverable_count: 0) if rows.empty?

      classification = classify(rows)

      if classification[:blocked_ids].any?
        raise Blocked, "#{classification[:blocked_ids].size} legacy attachment(s) on #{classification[:blocked_owners].size} owner(s) with no covering Media"
      end

      delete_ids = classification[:retained_ids] + classification[:releasing_ids] + classification[:orphaned_owner_ids]
      released_ids = classification[:releasing_ids] + classification[:orphaned_owner_ids]
      blob_ids = blob_ids_for(released_ids)
      released_bytes = bytes_for(blob_ids)

      deleted_count = delete_attachments(delete_ids)
      purge_blobs(blob_ids)

      Result.new(
        deleted_count:,
        released_blob_count: blob_ids.size,
        released_bytes:,
        unrecoverable_count: classification[:releasing_unrecoverable_ids].size
      )
    end

    private

    def legacy_rows
      ActiveStorage::Attachment
        .where(name: LEGACY_NAME)
        .joins(:blob)
        .pluck(:id, :record_type, :record_id, :blob_id)
    end

    def classify(rows)
      rows_by_type = rows.group_by { |row| row[1] }

      retained_blob_ids = ActiveStorage::Attachment
        .where.not(name: LEGACY_NAME)
        .where(blob_id: rows.map { |row| row[3] }.uniq)
        .distinct
        .pluck(:blob_id)
        .to_set

      covered_owner_keys = Media.joins(:image_attachment)
        .distinct
        .pluck(:mediaable_type, :mediaable_id)
        .to_set

      live_ids_by_type = rows_by_type.each_with_object({}) { |(type, type_rows), memo|
        memo[type] = type.constantize.where(id: type_rows.map { |row| row[2] }).pluck(:id).to_set
      }

      shopify_linked_ids_by_type = rows_by_type.each_with_object({}) { |(type, type_rows), memo|
        memo[type] = StoreInfo.shopify
          .where(storable_type: type, storable_id: type_rows.map { |row| row[2] })
          .where.not(store_id: [nil, ""])
          .distinct
          .pluck(:storable_id)
          .to_set
      }

      retained_ids = []
      releasing_ids = []
      releasing_unrecoverable_ids = []
      orphaned_owner_ids = []
      blocked_ids = []
      blocked_owners = Set.new

      rows.each do |id, record_type, record_id, blob_id|
        unless live_ids_by_type[record_type].include?(record_id)
          orphaned_owner_ids << id
          next
        end

        unless covered_owner_keys.include?([record_type, record_id])
          blocked_ids << id
          blocked_owners << [record_type, record_id]
          next
        end

        if retained_blob_ids.include?(blob_id)
          retained_ids << id
          next
        end

        if shopify_linked_ids_by_type[record_type].include?(record_id)
          releasing_ids << id
        else
          releasing_unrecoverable_ids << id
        end
      end

      {
        retained_ids:, releasing_ids:, releasing_unrecoverable_ids:,
        orphaned_owner_ids:, blocked_ids:, blocked_owners: blocked_owners.to_a
      }
    end

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
