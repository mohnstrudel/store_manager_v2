# frozen_string_literal: true

namespace :active_storage do
  desc "Report storage space that can be safely reclaimed without deleting anything"
  task reclaimable_space: :environment do
    cutoff_days = Integer(ENV.fetch("CUTOFF_DAYS", "30"))
    abort "CUTOFF_DAYS must be positive" unless cutoff_days.positive?

    cutoff = cutoff_days.days.ago
    bytes = ActiveStorage::Blob::ReclaimableSpace.bytes(cutoff:)
    size = ActiveSupport::NumberHelper.number_to_human_size(bytes)

    puts "Safely reclaimable: #{size}"
  end
end
