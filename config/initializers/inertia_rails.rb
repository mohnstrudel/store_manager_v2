# frozen_string_literal: true

InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  config.always_include_errors_hash = true
  config.ssr_enabled = ViteRuby.config.ssr_build_enabled
  config.ssr_cache = { expires_in: 1.hour }
end
