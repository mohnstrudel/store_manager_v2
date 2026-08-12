# frozen_string_literal: true

desc "Queue cleanup of safe legacy `images` attachments and their purge-candidate blobs."
task delete_legacy_image_attachments: :environment do
  begin
    result = Media::LegacyAttachments::Cleanup.enqueue!
  rescue Media::LegacyAttachments::Cleanup::Blocked => e
    abort "Refusing: #{e.message}. Run backfill_legacy_media_images first."
  end

  puts "Queued #{result.queued_batch_count} batch(es) for #{result.scheduled_attachment_count} " \
    "legacy attachment(s)."
  puts "#{result.purge_candidate_count} distinct purge-candidate blob(s), " \
    "#{result.purge_candidate_bytes} bytes, may be purged."

  if result.unrecoverable_count.positive?
    puts "Left #{result.unrecoverable_count} row(s) alone: owner has no Shopify link to re-pull from if this were wrong."
  end
end
