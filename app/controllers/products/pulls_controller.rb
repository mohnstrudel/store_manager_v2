# frozen_string_literal: true

module Products
  class PullsController < ApplicationController
    include JobsStatusNotice

    def create
      Shopify::PullProductsJob.perform_later(limit: params[:limit]&.to_i)
      Config.update_shopify_products_sync_time
      set_jobs_status_notice!

      redirect_back_or_to(products_path)
    end

    private

    def authorize_resourse
      authorize :product, :pull?
    end
  end
end
