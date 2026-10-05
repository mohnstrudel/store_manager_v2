# frozen_string_literal: true

if defined?(RailsLiveReload)
  RailsLiveReload.configure do |config|
    config.ignore %r{(^|/)(?:node_modules|\.agents|\.claude|\.codex)(/|$)}
  end
end
