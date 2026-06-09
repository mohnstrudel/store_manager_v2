# frozen_string_literal: true

module JobsStatusNotice
  extend ActiveSupport::Concern

  private

  def set_jobs_status_notice!
    flash[:notice] = {
      message: "Success! Visit",
      link: {
        label: "jobs statuses dashboard",
        href: "/jobs/statuses",
        suffix: "to track synchronization progress"
      }
    }
  end
end
