# frozen_string_literal: true

module Webhooks
  class SaleStatusesController < BaseController
    def create
      request_payload = JSON.parse(request.body.read, symbolize_names: true)
      order_id = request_payload[:orderIdentifier]

      return render json: {error: "Order identifier is required"}, status: :bad_request if order_id.blank?

      sale = Sale.find_recent_by_order_id(order_id)

      return render json: {error: "Order '#{order_id}' not found"}, status: :not_found if sale.blank?

      response = sale.sale_items.for_tracking_status.map do |sale_item|
        purchase_item = sale_item.purchase_items.first

        if purchase_item&.warehouse_id.present?
          warehouse = purchase_item.warehouse
          status = warehouse.external_name_de.presence || warehouse.external_name_en.presence || "No status available"
          description = warehouse.desc_de.presence || warehouse.desc_en.presence || "No description available"
        end

        {
          productName: sale_item.title,
          status:,
          description:
        }
      end

      final_response = response.one? ? response.first : response
      render json: final_response
    end

    private

    def authorize_resourse
      authorize :webhook, :sale_status?
    end
  end
end
