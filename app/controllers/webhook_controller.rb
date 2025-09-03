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
