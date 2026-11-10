# frozen_string_literal: true

module NotifiesRequester
  extend ActiveSupport::Concern

  FAILURE_ALERT_MEMORY = 30.days

  included do
    after_discard do |job, error|
      job.send(:notify_requester_of_discard, error)
    end
  end

  private

  def notify_requester_of_discard(error)
    notify_requester_of_failure(error) if error.is_a?(StandardError) && requester && claim_failure_alert
  end

  def requester
    options = arguments.last
    user = options[:requested_by] if options.is_a?(Hash)
    user if user.is_a?(User)
  end

  def claim_failure_alert
    Rails.cache.write("notifies_requester/failure_alert/#{job_id}", true, unless_exist: true, expires_in: FAILURE_ALERT_MEMORY)
  end

  def notify_requester_of_failure(error)
    requester&.notify(kind: :alert, **failure_notification(error))
  end

  def failure_notification(_error)
    raise NoMethodError, "#{self.class} must implement #failure_notification"
  end

  def notify_requester_of_success(message)
    requester&.notify(kind: :success, message:)
  end

  def jobs_dashboard_link
    {label: "Open the jobs dashboard", href: "/jobs/statuses"}
  end

  def broken_sales_link
    {label: "Open broken sales", href: Rails.application.routes.url_helpers.broken_sales_path}
  end
end
