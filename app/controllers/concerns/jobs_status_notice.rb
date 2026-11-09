# frozen_string_literal: true

module JobsStatusNotice
  extend ActiveSupport::Concern

  private

  def set_jobs_status_notice(message: "Success! Visit")
    flash[:notice] = {
      message:,
      link: {
        label: "jobs statuses dashboard",
        href: "/jobs/statuses",
        suffix: "to track synchronization progress"
      }
    }
  end
end
