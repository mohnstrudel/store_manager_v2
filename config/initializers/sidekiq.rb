# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = {ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}}
  Sidekiq::Status.configure_server_middleware config, expiration: 120.minutes.to_i
  Sidekiq::Status.configure_client_middleware config, expiration: 120.minutes.to_i

  config.capsule("media") do |capsule|
    capsule.concurrency = 2
    capsule.queues = %w[media]
  end
end

Sidekiq.configure_client do |config|
  config.redis = {ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}}
  Sidekiq::Status.configure_client_middleware config, expiration: 120.minutes.to_i
end
