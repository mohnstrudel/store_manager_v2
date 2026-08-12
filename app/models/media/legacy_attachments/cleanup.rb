# frozen_string_literal: true

class Media::LegacyAttachments::Cleanup
  BATCH_SIZE = 1_000

  class Blocked < StandardError; end
  class EnqueueFailed < StandardError; end

  Result = Data.define(
    :queued_batch_count,
    :scheduled_attachment_count,
    :purge_candidate_count,
    :purge_candidate_bytes,
    :unrecoverable_count
  )

  def self.enqueue!
    new.enqueue!
  end

  def self.delete_batch!(owner_type:, attachment_ids:, purge_blob_ids:)
    new.delete_batch!(owner_type:, attachment_ids:, purge_blob_ids:)
  end

  def enqueue!
    classifications = classifications_by_owner_class
    ensure_backfill_complete!(classifications)

    purgeable_blobs = purgeable_blobs(classifications)
    purge_candidate_count = purgeable_blobs.count
    purge_candidate_bytes = purgeable_blobs.sum(:byte_size)
    unrecoverable_count = classifications.sum do |_owner_class, classification|
      classification.unrecoverable.count
    end
    queued_batch_count = 0
    scheduled_attachment_count = 0

    classifications.each do |owner_class, classification|
      Media::LegacyAttachments::Classification::DELETABLE_RELATIONS.each do |scope_name|
        purge_blobs = %i[releasing orphaned_releasing].include?(scope_name)
        relation = classification.public_send(scope_name)
        batches, attachments = enqueue_scope!(owner_class, relation, purge_blobs:)
        queued_batch_count += batches
        scheduled_attachment_count += attachments
      end
    end

    Result.new(
      queued_batch_count:,
      scheduled_attachment_count:,
      purge_candidate_count:,
      purge_candidate_bytes:,
      unrecoverable_count:
    )
  end

  def delete_batch!(owner_type:, attachment_ids:, purge_blob_ids:)
    owner_class = Media::LegacyAttachments.owner_class_for!(owner_type)
    attachment_ids = normalize_ids(attachment_ids)
    purge_blob_ids = normalize_ids(purge_blob_ids)

    delete_safe_attachments!(owner_class, attachment_ids, purge_blob_ids)
    enqueue_purge_jobs!(purge_blob_ids)
  end

  private

  def classifications_by_owner_class
    Media::LegacyAttachments::OWNER_CLASSES.index_with do |owner_class|
      Media::LegacyAttachments::Classification.new(owner_class)
    end
  end

  def ensure_backfill_complete!(classifications)
    blocked_count = classifications.sum { |_owner_class, classification| classification.blocked.count }
    return if blocked_count.zero?

    blocked_owner_count = classifications.sum do |_owner_class, classification|
      classification.blocked.distinct.count(:record_id)
    end
    raise Blocked, "#{blocked_count} legacy attachment(s) on #{blocked_owner_count} owner(s) need backfill"
  end

  def purgeable_blobs(classifications)
    purge_relations = classifications.flat_map do |_owner_class, classification|
      [classification.releasing, classification.orphaned_releasing]
    end

    purge_relations.reduce(ActiveStorage::Blob.none) do |blobs, attachments|
      blobs.or(ActiveStorage::Blob.where(id: attachments.select(:blob_id)))
    end
  end

  def enqueue_scope!(owner_class, relation, purge_blobs:)
    queued_batch_count = 0
    scheduled_attachment_count = 0

    relation.in_batches(of: BATCH_SIZE) do |batch|
      rows = batch.pluck(:id, :blob_id)
      next if rows.empty?

      attachment_ids = rows.map(&:first)
      purge_blob_ids = purge_blobs ? rows.map(&:last).uniq : []
      job = Media::LegacyAttachments::CleanupJob.perform_later(
        owner_type: owner_class.name,
        attachment_ids:,
        purge_blob_ids:
      )
      unless job.respond_to?(:successfully_enqueued?) && job.successfully_enqueued?
        raise EnqueueFailed, "Failed to enqueue legacy attachment cleanup"
      end

      queued_batch_count += 1
      scheduled_attachment_count += attachment_ids.size
    end

    [queued_batch_count, scheduled_attachment_count]
  end

  def delete_safe_attachments!(owner_class, attachment_ids, purge_blob_ids)
    return if attachment_ids.empty?

    ActiveStorage::Attachment.transaction do
      existing_rows = legacy_attachments(owner_class).where(id: attachment_ids).lock.pluck(:id, :blob_id)
      next if existing_rows.empty?

      existing_ids = existing_rows.map(&:first)
      purge_blob_ids = purge_blob_ids.to_set
      purge_attachment_ids, retained_attachment_ids = existing_rows.partition do |_attachment_id, blob_id|
        purge_blob_ids.include?(blob_id)
      end.map { |rows| rows.map(&:first) }
      classification = Media::LegacyAttachments::Classification.new(owner_class)
      safe_ids = classification.deletable_with_purge.where(id: purge_attachment_ids).pluck(:id)
      safe_ids.concat(classification.deletable_without_purge.where(id: retained_attachment_ids).pluck(:id))
      unsafe = legacy_attachments(owner_class).where(id: existing_ids).where.not(id: safe_ids)
      if unsafe.exists?
        raise Blocked, "Legacy attachment batch is no longer safe to delete"
      end

      legacy_attachments(owner_class).where(id: existing_ids).delete_all
    end
  end

  def enqueue_purge_jobs!(blob_ids)
    ActiveStorage::Blob.where(id: blob_ids).find_each do |blob|
      job = blob.purge_later
      next if job.respond_to?(:successfully_enqueued?) && job.successfully_enqueued?

      raise EnqueueFailed, "Failed to enqueue purge for blob #{blob.id}"
    end
  end

  def normalize_ids(ids)
    Array(ids).map { |id| Integer(id) }.uniq
  end

  def legacy_attachments(owner_class)
    Media::LegacyAttachments.for_owner_class(owner_class)
  end
end
