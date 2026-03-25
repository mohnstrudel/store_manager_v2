# frozen_string_literal: true

module Dashboard
  class LastOrdersPullsController < ApplicationController
    def create
      Woo::PullSalesJob.perform_later(pages: 2)
      Config.enable_sales_hook

      redirect_back_or_to(
        root_path,
        notice: "Started getting missing sales. It'll take around 5–10 minutes"
      )
    end

    private

    def authorize_resourse
      authorize :dashboard, :pull_last_orders?
    end
  end
end
