# frozen_string_literal: true

module Sales
  class PullsController < ApplicationController
    include SaleScoped
    include JobsStatusNotice

    def create
      Shopify::PullSaleJob.perform_later(@sale.shopify_id) if @sale.shopify_id.present?
      Woo::PullSalesJob.set(wait: 90.seconds).perform_later(id: @sale.woo_id) if @sale.woo_id.present?
      set_jobs_status_notice!

      redirect_back_or_to(sales_path)
    end

    private

    def authorize_resourse
      authorize :sale, :pull?
    end
  end
end
