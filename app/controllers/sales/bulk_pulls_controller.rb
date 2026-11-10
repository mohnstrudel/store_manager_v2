# frozen_string_literal: true

module Sales
  class BulkPullsController < ApplicationController
    include JobsStatusNotice

    WOO_CHANGES_LIMIT = 100

    def create
      changes_only = params[:scope] == "changes"

      Shopify::PullSalesJob.perform_later(changes_only:, requested_by: Current.user)
      Woo::PullSalesJob.set(wait: 90.seconds).perform_later(limit: (WOO_CHANGES_LIMIT if changes_only), requested_by: Current.user)

      set_jobs_status_notice
      redirect_back_or_to(sales_path)
    end

    private

    def authorize_resource
      authorize :sale, :pull?
    end
  end
end
