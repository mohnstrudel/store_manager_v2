# frozen_string_literal: true

class Variant::AssignmentBackfillJob < ApplicationJob
  include NotifiesRequester

  queue_as :default
  discard_on(Variant::AssignmentBackfill::Failed) { |_job, error| Sentry.capture_exception(error) }

  def perform(requested_by: nil)
    result = Variant::AssignmentBackfill.call(env: {"APPLY" => "1"})
    raise Variant::AssignmentBackfill::Failed, result.failures if result.failures.any?

    notify_requester_of_success("#{job_title} finished.")
  end

  private

  def job_title
    "Broken sales repair"
  end

  def failure_notification(_error)
    {message: "Some broken sales could not be repaired.", link: broken_sales_link}
  end
end
