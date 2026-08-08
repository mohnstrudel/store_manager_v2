# frozen_string_literal: true

module Storage
  class ReclaimUnattachedBlobsJob < ApplicationJob
    queue_as :default

    GRACE_PERIOD = 2.days

    def perform
      return unless Rails.configuration.x.storage.delete_files

      reclaimable = ActiveStorage::Blob.unattached.where(created_at: ..GRACE_PERIOD.ago)
      count = reclaimable.count

      reclaimable.find_each(&:purge_later)

      Rails.logger.info("[Storage::ReclaimUnattachedBlobsJob] Enqueued #{count} unattached blob(s) for purge")
    end
  end
end
