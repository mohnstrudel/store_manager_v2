# frozen_string_literal: true

module Sales
  class PullsController < ApplicationController
    include SaleScoped
    include JobsStatusNotice

    def create
      shopify_id = @sale.shopify_store_id
      woo_id = @sale.woo_store_id

      Shopify::PullSaleJob.perform_later(shopify_id, requested_by: Current.user) if shopify_id
      Woo::PullSalesJob.set(wait: 90.seconds).perform_later(id: woo_id, requested_by: Current.user) if woo_id

      set_jobs_status_notice(message: "Started pulling this order from the store. You'll get a notification when it finishes. To follow progress, open the")
      redirect_back_or_to(sales_path)
    end

    private

    def authorize_resource
      authorize :sale, :pull?
    end
  end
end
