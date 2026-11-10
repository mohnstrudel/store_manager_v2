# frozen_string_literal: true

module Webhooks
  class OrderUpdatesController < BaseController
    before_action :ensure_webhook_is_verified

    def create
      request_payload = JSON.parse(request.body.read, symbolize_names: true)
      import_or_pull_later(request_payload)

      head(:no_content)
    end

    private

    def import_or_pull_later(request_payload)
      Sale::Woo::Importer.import(Sale::Woo::Parser.parse(request_payload))
    rescue Woo::Api::Client::Unavailable
      Woo::PullSalesJob.perform_later(id: request_payload[:id].to_s)
    end

    def ensure_webhook_is_verified
      head :unauthorized unless verify_webhook(ENV.fetch("WOO_WEBHOOK_SECRET"))
    end

    def authorize_resource
      authorize :webhook, :process_order?
    end
  end
end
