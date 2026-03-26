# frozen_string_literal: true

module Webhooks
  class OrderUpdatesController < BaseController
    def create
      verified = verify_webhook(Rails.application.credentials.dig(:hooks, :order))
      return head(:unauthorized) unless verified

      request_payload = JSON.parse(request.body.read, symbolize_names: true)
      job = Woo::PullSalesJob.new
      parsed_order = job.parse(request_payload)
      job.create_sales([parsed_order])

      head(:no_content)
    end

    private

    def authorize_resourse
      authorize :webhook, :process_order?
    end
  end
end
