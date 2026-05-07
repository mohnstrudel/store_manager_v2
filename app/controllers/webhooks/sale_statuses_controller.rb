# frozen_string_literal: true

module Webhooks
  class SaleStatusesController < BaseController
    def create
      request_payload = JSON.parse(request.body.read, symbolize_names: true)
      order_id = request_payload[:orderIdentifier]

      return render json: {error: "Order identifier is required"}, status: :bad_request if order_id.blank?

      sale = Sale.find_recent_by_order_id(order_id)

      return render json: {error: "Order '#{order_id}' not found"}, status: :not_found if sale.blank?

      render json: sale.item_tracking_payload
    end

    private

    def authorize_resourse
      authorize :webhook, :sale_status?
    end
  end
end
