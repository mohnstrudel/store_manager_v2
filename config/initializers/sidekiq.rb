Sidekiq.configure_server do |config|
  config.redis = {ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}}
end

Sidekiq.configure_client do |config|
  config.redis = {ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}}
end

# Fix for Turbo+Sidekiq from: https://github.com/hotwired/turbo-rails/issues/535
Rails.application.config.after_initialize do
  Turbo::Streams::BroadcastStreamJob.class_eval do
    def self.perform_later(stream, content:)
      super(stream, content: content.to_str)
    end
  end
end
