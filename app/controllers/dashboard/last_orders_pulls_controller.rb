# frozen_string_literal: true

module Dashboard
  class LastOrdersPullsController < ApplicationController
    def create
      Woo::PullSalesJob.perform_later(pages: 2, requested_by: Current.user)
      Config.enable_sales_hook

      redirect_back_or_to(
        root_path,
        notice: "Started getting missing sales. It takes about 5–10 minutes. You'll get a notification when it finishes."
      )
    end

    private

    def authorize_resource
      authorize :dashboard, :pull_last_orders?
    end
  end
end
