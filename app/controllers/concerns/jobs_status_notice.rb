# frozen_string_literal: true

module JobsStatusNotice
  extend ActiveSupport::Concern
  include ActionView::Helpers::OutputSafetyHelper

  private

  def set_jobs_status_notice!
    statuses_link = view_context.link_to(
      "jobs statuses dashboard", root_url + "jobs/statuses", class: "link"
    )

    flash[:notice] = safe_join([
      "Success! Visit ",
      statuses_link,
      " to track synchronization progress"
    ])
  end
end
