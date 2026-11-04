# frozen_string_literal: true

module Webhooks
  class OrderUpdatesController < BaseController
    def create
      verified = verify_webhook(Rails.application.credentials.dig(:hooks, :order))
      return head(:unauthorized) unless verified

      request_payload = JSON.parse(request.body.read, symbolize_names: true)
      Sale::Woo::Importer.import_all!([Sale::Woo::Parser.parse(request_payload)])

      head(:no_content)
    end

    private

    def authorize_resource
      authorize :webhook, :process_order?
    end
  end
end
