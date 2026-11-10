# frozen_string_literal: true

module NotifiesRequester
  extend ActiveSupport::Concern

  included do
    after_discard do |job, error|
      job.send(:notify_requester_of_failure, error)
    end
  end

  private

  def notify_requester_of_failure(error)
    requester&.notify(kind: :alert, **failure_notification(error))
  end

  def requester
    options = arguments.last
    user = options[:requested_by] if options.is_a?(Hash)
    user if user.is_a?(User)
  end

  def failure_notification(_error)
    raise NotImplementedError, "#{self.class} must implement #failure_notification"
  end

  def notify_requester_of_success(message)
    requester&.notify(kind: :notice, message:)
  end

  def jobs_dashboard_link
    {label: "Open the jobs dashboard", href: "/jobs/statuses"}
  end

  def broken_sales_link
    {label: "Open broken sales", href: Rails.application.routes.url_helpers.broken_sales_path}
  end
end
