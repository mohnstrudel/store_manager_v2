# frozen_string_literal: true

module Sales
  class PullsController < ApplicationController
    include SaleScoped
    include JobsStatusNotice

    def create
      shopify_id = @sale.shopify_info&.store_id
      woo_id = @sale.woo_info&.store_id

      Shopify::PullSaleJob.perform_later(shopify_id) if shopify_id
      Woo::PullSalesJob.set(wait: 90.seconds).perform_later(id: woo_id) if woo_id

      set_jobs_status_notice!
      redirect_back_or_to(sales_path)
    end

    private

    def authorize_resourse
      authorize :sale, :pull?
    end
  end
end
