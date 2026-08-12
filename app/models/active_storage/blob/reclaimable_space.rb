# frozen_string_literal: true

class ActiveStorage::Blob::ReclaimableSpace
  ACTIVE_STORAGE_KEY_PATTERN = /\A[0-9a-z]{28}\z/
  BATCH_SIZE = 1_000
  DEFAULT_CUTOFF_AGE = 30.days
  VARIANT_PREFIX = "variants/"

  class UnsupportedService < StandardError; end

  def self.bytes(cutoff: DEFAULT_CUTOFF_AGE.ago, service: ActiveStorage::Blob.service)
    new(cutoff:, service:).bytes
  end

  def initialize(cutoff:, service:)
    @cutoff = cutoff
    @service = service
  end

  def bytes
    ensure_listable_service!
    reclaimable_bytes = 0
    batch = []

    service.bucket.objects.each do |object|
      batch << object
      next unless batch.size == BATCH_SIZE

      reclaimable_bytes += reclaimable_bytes_for(batch)
      batch.clear
    end
    reclaimable_bytes += reclaimable_bytes_for(batch) if batch.any?

    reclaimable_bytes
  end

  private

  attr_reader :cutoff, :service

  def ensure_listable_service!
    return if service.respond_to?(:name) && service.respond_to?(:bucket)

    raise UnsupportedService, "Configured Active Storage service does not support object listing"
  end

  def service_name
    service.name.to_s
  end

  def reclaimable_bytes_for(objects)
    blob_states = blob_states_for(objects)

    objects.sum do |object|
      reclaimable?(object, blob_states) ? object.size : 0
    end
  end

  def blob_states_for(objects)
    parent_keys = objects.filter_map { |object| parent_blob_key(object.key) }.uniq

    ActiveStorage::Blob
      .where(key: parent_keys)
      .left_joins(:attachments)
      .group(:id)
      .pluck(:key, :service_name, :created_at, Arel.sql("COUNT(active_storage_attachments.id)"))
      .to_h do |key, blob_service_name, created_at, attachment_count|
        reclaimable = blob_service_name == service_name && created_at <= cutoff && attachment_count.zero?
        [key, reclaimable]
      end
  end

  def reclaimable?(object, blob_states)
    return false if object.last_modified > cutoff

    parent_key = parent_blob_key(object.key)
    return false unless parent_key
    return blob_states.fetch(parent_key) if blob_states.key?(parent_key)

    parent_key.match?(ACTIVE_STORAGE_KEY_PATTERN)
  end

  def parent_blob_key(key)
    return key unless key.start_with?(VARIANT_PREFIX)

    parent_key, variation_key = key.delete_prefix(VARIANT_PREFIX).split("/", 2)
    parent_key if parent_key.present? && variation_key.present?
  end
end
