# frozen_string_literal: true

if defined?(RailsLiveReload)
  RailsLiveReload.configure do |config|
    # pnpm creates nested symlinks inside node_modules/.pnpm, which can confuse
    # Listen and produce duplicate watch warnings during development boot.
    config.ignore %r{(^|/)node_modules/}
  end
end
