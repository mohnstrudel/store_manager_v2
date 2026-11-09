# frozen_string_literal: true

module BrokenSales
  class BackfillsController < ApplicationController
    include JobsStatusNotice

    def create
      Variant::AssignmentBackfillJob.perform_later
      set_jobs_status_notice

      redirect_to broken_sales_path
    end

    private

    def authorize_resource
      authorize :broken_sale, :update?
    end
  end
end
