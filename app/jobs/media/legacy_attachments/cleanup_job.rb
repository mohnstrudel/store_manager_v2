# frozen_string_literal: true

class Media::LegacyAttachments::CleanupJob < ApplicationJob
  queue_as :default

  def perform(owner_type:, attachment_ids:, purge_blob_ids:)
    Media::LegacyAttachments::Cleanup.delete_batch!(owner_type:, attachment_ids:, purge_blob_ids:)
  end
end
