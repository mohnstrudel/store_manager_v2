# frozen_string_literal: true

namespace :variant_assignments do
  desc "Dry-run or apply deterministic Variant assignment repairs"
  task backfill: :environment do
    result = Variant::AssignmentBackfill.call
    abort "Variant assignment backfill recorded #{result.failures.size} failure(s)" if result.failures.any?
  end
end
