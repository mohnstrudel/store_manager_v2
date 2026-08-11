# frozen_string_literal: true

namespace :storage do
  desc "Report bucket objects with no matching active_storage_blobs row. Deletes nothing."
  task audit_bucket_orphans: :environment do
    result = Storage::BucketOrphanAudit.call

    puts "Found #{result.count} orphaned object(s), #{result.total_bytes} bytes total."
    result.orphan_keys.first(50).each { |key| puts "  #{key}" }
  end

  desc "Delete audited bucket orphans. Requires CONFIRM=yes."
  task delete_bucket_orphans: :environment do
    unless ENV["CONFIRM"] == "yes"
      abort "Refusing: set CONFIRM=yes to proceed."
    end

    result = Storage::BucketOrphanAudit.call
    service = ActiveStorage::Blob.service

    result.orphan_keys.each do |key|
      service.delete(key)
      puts "Deleted #{key}"
    end

    puts "Deleted #{result.count} object(s), #{result.total_bytes} bytes reclaimed."
  end

  desc "Report legacy `images` attachment rows by deletion safety. Deletes nothing."
  task audit_legacy_image_attachments: :environment do
    result = Storage::LegacyImageAttachmentAudit.call

    puts "Total legacy attachment(s): #{result.total}"
    puts "  retained (blob stays attached elsewhere): #{result.retained_ids.size}"
    puts "  releasing (blob becomes unattached, Shopify-recoverable): #{result.releasing_ids.size}"
    puts "  releasing_unrecoverable (no Shopify link to re-pull from): #{result.releasing_unrecoverable_ids.size}"
    puts "  orphaned_owner (owner record no longer exists): #{result.orphaned_owner_ids.size}"
    puts "  blocked (owner has no covering Media, must not delete): #{result.blocked_ids.size} across #{result.blocked_owners.size} owner(s)"
    puts "Releasing bytes: #{result.releasing_bytes}"

    if result.blocked_owners.any?
      puts "Blocked owners (first 20):"
      result.blocked_owners.first(20).each { |type, id| puts "  #{type}##{id}" }
    end
  end

  desc "Delete legacy `images` attachment rows. Requires CONFIRM=yes. SCOPE=retained (default) or all."
  task delete_legacy_image_attachments: :environment do
    unless ENV["CONFIRM"] == "yes"
      abort "Refusing: set CONFIRM=yes to proceed."
    end

    scope = (ENV["SCOPE"] || "retained").to_sym
    unless [:retained, :all].include?(scope)
      abort "Refusing: SCOPE must be 'retained' or 'all', got #{scope.inspect}."
    end

    allow_unrecoverable = ENV["ALLOW_UNRECOVERABLE"] == "yes"

    begin
      result = Storage::LegacyImageAttachmentCleanup.call(scope:, allow_unrecoverable:)
    rescue Storage::LegacyImageAttachmentCleanup::Blocked => e
      abort "Refusing: #{e.message}. Run backfill_legacy_media_images first."
    end

    puts "Deleted #{result.deleted_count} legacy attachment(s), released #{result.released_blob_count} " \
      "blob(s) for purge, #{result.released_bytes} bytes."
  end
end
