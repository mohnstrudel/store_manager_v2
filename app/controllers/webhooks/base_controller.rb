# frozen_string_literal: true

module Webhooks
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_authentication
    skip_before_action :set_sentry_user

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
end
