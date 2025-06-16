Sentry.init do |config|
  config.enabled_environments = %w[production]
  config.dsn = ENV["SENTRY_DSN"]

  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true

  # Learn how to configure the volume of error and transaction events
  # sent to Sentry:
  # https://docs.sentry.io/platforms/ruby/configuration/sampling/
  config.traces_sample_rate = 1.0
end
