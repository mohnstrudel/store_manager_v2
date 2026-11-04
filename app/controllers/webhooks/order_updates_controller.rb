# frozen_string_literal: true

module Webhooks
  class OrderUpdatesController < BaseController
    before_action :ensure_webhook_is_verified

    def create
      request_payload = JSON.parse(request.body.read, symbolize_names: true)
      Sale::Woo::Importer.import_all([Sale::Woo::Parser.parse(request_payload)])

      head(:no_content)
    end

    private

    def ensure_webhook_is_verified
      head :unauthorized unless verify_webhook(Rails.application.credentials.dig(:hooks, :order))
    end

    def authorize_resource
      authorize :webhook, :process_order?
    end
  end
end
