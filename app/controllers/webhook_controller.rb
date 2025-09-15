class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_authentication
  skip_before_action :set_sentry_user

  SYNC_ORDERS_JOB = SyncWooOrdersJob.new

  def process_order
    verified = verify_webhook(Rails.application.credentials.dig(:hooks, :order))
    return head(:unauthorized) unless verified

    request_payload = JSON.parse(request.body.read, symbolize_names: true)
    parsed_order = SYNC_ORDERS_JOB.parse(request_payload)
    SYNC_ORDERS_JOB.create_sales([parsed_order])

    head(:no_content)
  end

  def sale_status
    request_payload = JSON.parse(request.body.read, symbolize_names: true)
    order_id = request_payload[:orderIdentifier]

    return render json: {error: "Order identifier is required"}, status: :bad_request if order_id.blank?

    sale = Sale.find_recent_by_order_id(order_id)

    return render json: {error: "Order '#{order_id}' not found"}, status: :not_found if sale.blank?

    response = sale.sale_items.with_purchase_details.map do |sale_item|
      # Sale items have the 'qty' field, but we assume it's one for simplicity
      purchase_item = sale_item.purchase_items.first

      if purchase_item&.warehouse.present?
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

  # "x-wc-webhook-signature" is a HMAC:
  # a base64 encoded HMAC-SHA256 hash of the payload
  def verify_webhook(secret)
    payload = request.body.read
    req_sign = request.headers["x-wc-webhook-signature"]
    calc_sign = Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, payload))
    ActiveSupport::SecurityUtils.secure_compare(calc_sign, req_sign)
  end
end
