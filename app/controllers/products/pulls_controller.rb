# frozen_string_literal: true

module Products
  class PullsController < ApplicationController
    include JobsStatusNotice

    def create
      Shopify::PullProductsJob.perform_later(changes_only: params[:scope] == "changes")
      set_jobs_status_notice

      redirect_back_or_to(products_path)
    end

    private

    def authorize_resource
      authorize :product, :pull?
    end
  end
end
