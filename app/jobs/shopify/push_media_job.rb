# frozen_string_literal: true

module Shopify
  class PushMediaJob < Shopify::ApiJob
    retry_on(Product::Shopify::Media::Push::NotReady, wait: 10.seconds, attempts: 60) do |_job, error|
      Sentry.capture_exception(error)
    end
    discard_on(Product::Shopify::Media::Push::MediaFailed) { |_job, error| Sentry.capture_exception(error) }

    def perform(product_id, product_store_id)
      Product::Shopify::Media::Push.call(product_id:, product_store_id:)
    end
  end
end
