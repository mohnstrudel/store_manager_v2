# frozen_string_literal: true

module VariantAssignmentIssues
  class BackfillsController < ApplicationController
    include JobsStatusNotice

    def create
      Variant::AssignmentBackfillJob.perform_later
      set_jobs_status_notice!

      redirect_to variant_assignment_issues_path
    end

    private

    def authorize_resource
      authorize :variant_assignment_issue, :update?
    end
  end
end
