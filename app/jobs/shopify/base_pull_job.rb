# frozen_string_literal: true

module Shopify
  class BasePullJob < ApplicationJob
    queue_as :default
    discard_on(Shopify::Pull::Failed) { |_job, error| Sentry.capture_exception(error) }

    def perform(attempts: 0, cursor: nil, limit: nil)
      page = pull_class.page(cursor:, limit:)

      if limit.blank? && page.next_cursor
        self.class.set(wait: 1.second).perform_later(cursor: page.next_cursor)
      else
        handle_terminal_page
      end

      raise Shopify::Pull::Failed, page.failures if page.failures.any?
    rescue ShopifyAPI::Errors::HttpResponseError => e
      raise unless e.response.code == 429

      self.class.set(wait: (attempts * 5 + 5).seconds).perform_later(attempts: attempts + 1, cursor:, limit:)
    end

    private

    def pull_class
      raise NotImplementedError, "#{self.class} must implement #pull_class"
    end

    def handle_terminal_page
    end
  end
end
