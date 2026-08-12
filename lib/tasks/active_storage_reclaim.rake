# frozen_string_literal: true

namespace :active_storage do
  desc "Queue deletion of safely reclaimable Active Storage objects"
  task reclaim: :environment do
    cutoff_days = Integer(ENV.fetch("CUTOFF_DAYS", "30"))
    abort "CUTOFF_DAYS must be positive" unless cutoff_days.positive?

    cutoff = cutoff_days.days.ago
    ActiveStorage::Blob::Reclamation.enqueue!(cutoff:)

    puts "Queued safe Active Storage reclamation for objects older than #{cutoff.iso8601}."
  rescue ActiveStorage::Blob::Reclamation::EnqueueFailed => e
    abort e.message
  end
end
