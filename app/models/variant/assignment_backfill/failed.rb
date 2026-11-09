# frozen_string_literal: true

class Variant::AssignmentBackfill::Failed < StandardError
  DESCRIBED_LIMIT = 10

  attr_reader :failures

  def initialize(failures)
    @failures = failures
    super(build_message)
  end

  private

  def build_message
    described = failures.first(DESCRIBED_LIMIT).map(&:inspect).join(", ")
    omitted = failures.size - DESCRIBED_LIMIT
    suffix = (omitted > 0) ? " (and #{omitted} more)" : ""
    "Variant assignment backfill recorded #{failures.size} failure(s): #{described}#{suffix}"
  end
end
