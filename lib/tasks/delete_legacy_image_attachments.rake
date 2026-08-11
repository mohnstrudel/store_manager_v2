# frozen_string_literal: true

desc "Delete legacy `images` attachment rows that are safe to delete, purging blobs they were the last reference to."
task delete_legacy_image_attachments: :environment do
  begin
    result = Storage::LegacyImageAttachmentCleanup.call
  rescue Storage::LegacyImageAttachmentCleanup::Blocked => e
    abort "Refusing: #{e.message}. Run backfill_legacy_media_images first."
  end

  puts "Deleted #{result.deleted_count} legacy attachment(s), released #{result.released_blob_count} " \
    "blob(s) for purge, #{result.released_bytes} bytes."

  if result.unrecoverable_count.positive?
    puts "Left #{result.unrecoverable_count} row(s) alone: owner has no Shopify link to re-pull from if this were wrong."
  end
end
