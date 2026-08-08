# frozen_string_literal: true

namespace :storage do
  delete_consequences = <<~MSG
    Deleting these objects reclaims:
      - genuinely stranded files, the ones worth reclaiming
      - AND every object local/staging created since their last production database restore,
        which from production is indistinguishable from the first group
    The second group breaks images in those environments until they re-pull from Shopify.
    Recoverable, but disruptive.
  MSG

  desc "Report bucket objects with no matching active_storage_blobs row. Deletes nothing."
  task audit_bucket_orphans: :environment do
    puts delete_consequences

    result = Storage::BucketOrphanAudit.call

    puts "Found #{result.count} orphaned object(s), #{result.total_bytes} bytes total."
    result.orphan_keys.first(50).each { |key| puts "  #{key}" }
  end

  desc "Delete audited bucket orphans. Requires config.x.storage.delete_files and CONFIRM=yes; production only."
  task delete_bucket_orphans: :environment do
    puts delete_consequences

    unless Rails.configuration.x.storage.delete_files
      abort "Refusing: config.x.storage.delete_files is false here. This task may only run in " \
        "production, the only environment whose database is authoritative for what the bucket should contain."
    end

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
end
