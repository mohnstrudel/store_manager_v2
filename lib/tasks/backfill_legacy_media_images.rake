# frozen_string_literal: true

desc "One-time backfill: create missing Media for legacy `images` attachments"
task backfill_legacy_media_images: :environment do
  result = Media::LegacyAttachments::Backfill.apply!

  puts "Backfilled #{result.owners_backfilled} owner(s), created #{result.created_count} Media record(s)."
end
