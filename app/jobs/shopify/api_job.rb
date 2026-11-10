# frozen_string_literal: true

module Shopify
  class ApiJob < ApplicationJob
    THROTTLE_ATTEMPTS = 10
    THROTTLE_WAIT_SECONDS = (1..60)
    THROTTLE_JITTER = 0.25

    retry_on Shopify::Api::Client::Throttled, wait: ->(executions) { 2**executions }, attempts: THROTTLE_ATTEMPTS

    def retry_job(options = {})
      error = options[:error]
      return super unless error.is_a?(Shopify::Api::Client::Throttled)

      super(options.merge(wait: throttle_wait(error.retry_after || options[:wait])))
    end

    private

    def throttle_wait(seconds)
      wait = seconds.to_f.clamp(THROTTLE_WAIT_SECONDS)
      wait + (rand * wait * THROTTLE_JITTER)
    end
  end
end
