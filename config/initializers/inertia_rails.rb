# frozen_string_literal: true

InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  config.always_include_errors_hash = true
  config.ssr_enabled = true
  config.ssr_cache = { expires_in: 1.hour }
end
