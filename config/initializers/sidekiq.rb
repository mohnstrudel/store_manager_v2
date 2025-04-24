Sidekiq.configure_server do |config|
  config.redis = {ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}}
  Sidekiq::Status.configure_server_middleware config, expiration: 120.minutes.to_i
  Sidekiq::Status.configure_client_middleware config, expiration: 120.minutes.to_i
end

Sidekiq.configure_client do |config|
  config.redis = {ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}}
  Sidekiq::Status.configure_client_middleware config, expiration: 120.minutes.to_i
end

# Fix for Turbo+Sidekiq from: https://github.com/hotwired/turbo-rails/issues/535
Rails.application.config.after_initialize do
  Turbo::Streams::BroadcastStreamJob.class_eval do
    def self.perform_later(stream, content:)
      super(stream, content: content.to_str)
    end
  end
end
