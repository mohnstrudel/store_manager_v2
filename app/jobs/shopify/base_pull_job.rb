# frozen_string_literal: true

module Shopify
  class BasePullJob < Shopify::ApiJob
    queue_as :default
    discard_on(Shopify::Pull::Failed) { |_job, error| Sentry.capture_exception(error) }

    def perform(cursor: nil, limit: nil)
      page = pull_class.page(cursor:, limit:)

      if limit.blank? && page.next_cursor
        self.class.perform_later(cursor: page.next_cursor)
      else
        handle_terminal_page
      end

      raise Shopify::Pull::Failed, page.failures if page.failures.any?
    end

    private

    def pull_class
      raise NotImplementedError, "#{self.class} must implement #pull_class"
    end

    def handle_terminal_page
    end
  end
end
