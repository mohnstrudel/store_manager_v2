# frozen_string_literal: true

class Media::LegacyAttachmentCleanup
  LEGACY_NAME = "images"
  BATCH_SIZE = 1_000
  MODELS = [Product, Warehouse].freeze
  class Blocked < StandardError; end
  Result = Data.define(:deleted_count, :released_blob_count, :released_bytes, :unrecoverable_count)

  def self.call
    new.call
  end

  def call
    blocked_count = 0
    blocked_owner_count = 0
    retained_ids = []
    releasing_ids = []
    unrecoverable_ids = []
    orphaned_ids = []

    MODELS.each do |model|
      scopes = classify(model)
      blocked_count += scopes[:blocked].count
      blocked_owner_count += scopes[:blocked].distinct.count(:record_id)
      retained_ids.concat(scopes[:retained].pluck(:id))
      releasing_ids.concat(scopes[:releasing].pluck(:id))
      unrecoverable_ids.concat(scopes[:releasing_unrecoverable].pluck(:id))
      orphaned_ids.concat(scopes[:orphaned_owner].pluck(:id))
    end

    if blocked_count.positive?
      raise Blocked, "#{blocked_count} legacy attachment(s) on #{blocked_owner_count} owner(s) with no covering Media"
    end

    delete_ids = retained_ids + releasing_ids + orphaned_ids
    released_ids = releasing_ids + orphaned_ids
    blob_ids = blob_ids_for(released_ids)
    released_bytes = bytes_for(blob_ids)

    deleted_count = delete_attachments(delete_ids)
    purge_blobs(blob_ids)

    Result.new(
      deleted_count:,
      released_blob_count: blob_ids.size,
      released_bytes:,
      unrecoverable_count: unrecoverable_ids.size
    )
  end

  private

  def classify(model)
    legacy = ActiveStorage::Attachment.where(name: LEGACY_NAME, record_type: model.name)
    live = legacy.where(record_id: model.select(:id))
    orphaned_owner = legacy.where.not(record_id: model.select(:id))

    covered_owner_ids = Media.joins(:image_attachment).where(mediaable_type: model.name).select(:mediaable_id)
    covered = live.where(record_id: covered_owner_ids)
    blocked = live.where.not(record_id: covered_owner_ids)

    other_attachment_blob_ids = ActiveStorage::Attachment.where.not(name: LEGACY_NAME).select(:blob_id)
    retained = covered.where(blob_id: other_attachment_blob_ids)
    releasing_all = covered.where.not(blob_id: other_attachment_blob_ids)

    shopify_linked_owner_ids = StoreInfo.shopify.where(storable_type: model.name).where.not(store_id: [nil, ""]).select(:storable_id)
    releasing = releasing_all.where(record_id: shopify_linked_owner_ids)
    releasing_unrecoverable = releasing_all.where.not(record_id: shopify_linked_owner_ids)

    {retained:, releasing:, releasing_unrecoverable:, orphaned_owner:, blocked:}
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
