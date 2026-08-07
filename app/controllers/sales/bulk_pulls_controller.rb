# frozen_string_literal: true

module Sales
  class BulkPullsController < ApplicationController
    include JobsStatusNotice

    def create
      limit = params[:limit]

      Config.update_shopify_sales_sync_time

      Shopify::PullSalesJob.perform_later(limit:)
      Seal::SyncPaymentPlansJob.perform_later
      Woo::PullSalesJob.set(wait: 90.seconds).perform_later(limit:)

      set_jobs_status_notice!
      redirect_back_or_to(sales_path)
    end

    private

    def authorize_resource
      authorize :sale, :pull?
    end
  end
end
