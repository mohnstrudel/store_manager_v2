# frozen_string_literal: true

class ActiveStorage::Blob::Reclamation
  class DeleteFailed < StandardError; end
  class EnqueueFailed < StandardError; end

  Result = Data.define(:deleted_object_count, :deleted_bytes)

  def self.apply!(cutoff:, service: ActiveStorage::Blob.service)
    new(cutoff:, service:).apply!
  end

  def self.enqueue!(cutoff: ActiveStorage::Blob::ReclaimableSpace::DEFAULT_CUTOFF_AGE.ago)
    job = ActiveStorage::Blob::ReclamationJob.perform_later(cutoff: cutoff.iso8601)
    return job if job.respond_to?(:successfully_enqueued?) && job.successfully_enqueued?

    raise EnqueueFailed, "Failed to enqueue Active Storage reclamation"
  end

  def initialize(cutoff:, service:)
    @cutoff = cutoff
    @service = service
  end

  def apply!
    deleted_object_count = 0
    deleted_bytes = 0

    reclaimable_space.each_reclaimable_batch do |candidates|
      safe_candidates = revalidate_and_release_blobs!(candidates)
      next if safe_candidates.empty?

      delete_objects!(safe_candidates)
      deleted_object_count += safe_candidates.size
      deleted_bytes += safe_candidates.sum(&:size)
    end

    Result.new(deleted_object_count:, deleted_bytes:)
  end

  private

  attr_reader :cutoff, :service

  def reclaimable_space
    ActiveStorage::Blob::ReclaimableSpace.new(cutoff:, service:)
  end

  def revalidate_and_release_blobs!(candidates)
    parent_keys = candidates.map(&:parent_key).uniq
    safe_parent_keys = []

    ActiveStorage::Blob.transaction do
      blobs = ActiveStorage::Blob.where(key: parent_keys).lock.index_by(&:key)
      attachment_counts = ActiveStorage::Attachment.where(blob_id: blobs.values).group(:blob_id).count

      safe_parent_keys = parent_keys.select do |parent_key|
        blob = blobs[parent_key]
        blob.nil? || safe_blob?(blob, attachment_counts)
      end

      safe_parent_keys.each { |parent_key| blobs[parent_key]&.destroy! }
    end

    safe_parent_keys = safe_parent_keys.index_with(true)
    candidates.select { |candidate| safe_parent_keys.key?(candidate.parent_key) }
  end

  def safe_blob?(blob, attachment_counts)
    blob.service_name == service.name.to_s && blob.created_at <= cutoff && attachment_counts[blob.id].to_i.zero?
  end

  def delete_objects!(candidates)
    response = service.bucket.delete_objects(
      delete: {objects: candidates.map { |candidate| {key: candidate.key} }}
    )
    return if response.errors.empty?

    details = response.errors.map { |error| "#{error.key}: #{error.message}" }.join(", ")
    raise DeleteFailed, "Failed to delete reclaimable object(s): #{details}"
  end
end
