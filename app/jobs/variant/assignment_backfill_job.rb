# frozen_string_literal: true

class Variant::AssignmentBackfillJob < ApplicationJob
  queue_as :default

  def perform
    result = Variant::AssignmentBackfill.call(env: {"APPLY" => "1"})
    return if result.failures.empty?

    raise Variant::AssignmentBackfill::Failed, result.failures
  end
end
