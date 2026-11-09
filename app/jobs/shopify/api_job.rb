# frozen_string_literal: true

module Shopify
  class ApiJob < ApplicationJob
    retry_on Shopify::Api::Client::Throttled, wait: :polynomially_longer, attempts: 10
  end
end
