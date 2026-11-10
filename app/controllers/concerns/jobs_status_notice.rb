# frozen_string_literal: true

module JobsStatusNotice
  extend ActiveSupport::Concern

  private

  def set_jobs_status_notice(message: "Started. You'll get a notification when it finishes. To follow progress, open the")
    flash[:notice] = {
      message:,
      link: {
        label: "jobs dashboard",
        href: "/jobs/statuses"
      }
    }
  end
end
