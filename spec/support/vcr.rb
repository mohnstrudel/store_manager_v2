# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.ignore_localhost = true
  config.allow_http_connections_when_no_cassette = false
  config.default_cassette_options = {record: :once, match_requests_on: %i[method uri]}

  config.filter_sensitive_data("<SHOPIFY_DOMAIN>") { ENV["SHOPIFY_DOMAIN"] }
  config.filter_sensitive_data("<SHOPIFY_API_TOKEN>") { ENV["SHOPIFY_API_TOKEN"] }
  config.filter_sensitive_data("<WOO_API_USER>") { ENV.fetch("WOO_API_USER", nil) }
  config.filter_sensitive_data("<WOO_API_PASS>") { ENV.fetch("WOO_API_PASS", nil) }
  config.filter_sensitive_data("<SEAL_SUBSCRIPTIONS_API_TOKEN>") { ENV.fetch("SEAL_SUBSCRIPTIONS_API_TOKEN", nil) }
end

WebMock.disable_net_connect!(allow_localhost: true)
