class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create_order
    verified = verify_webhook(Rails.application.credentials.dig(:hooks, :order))
    return head(:unauthorized) unless verified
    # TODO: https://github.com/mohnstrudel/store_manager_v2/issues/7
    # request.body.read || params.to_json
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
