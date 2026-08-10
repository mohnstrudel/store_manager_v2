# frozen_string_literal: true

desc "One-time backfill: create Media for legacy `images` attachments on owners with no image-bearing Media yet"
task backfill_legacy_media_images: :environment do
  result = Media::LegacyAttachmentBackfill.call

  puts "Backfilled #{result.owners_backfilled} owner(s), created #{result.created_count} Media record(s)."
end
