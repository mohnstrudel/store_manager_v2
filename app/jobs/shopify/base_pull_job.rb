# frozen_string_literal: true

module Shopify
  class BasePullJob < Shopify::ApiJob
    CHANGES_OVERLAP = 15.minutes

    queue_as :default
    discard_on(Shopify::Pull::Failed) { |_job, error| Sentry.capture_exception(error) }

    def perform(changes_only: false, cursor: nil, started_at: nil, updated_since: nil)
      if cursor.nil?
        started_at = Time.current
        updated_since = changes_since if changes_only
      end

      page = pull_class.page(cursor:, updated_since:)

      if page.next_cursor
        self.class.perform_later(cursor: page.next_cursor, started_at:, updated_since:)
      else
        complete_pull(started_at:, updated_since:)
      end

      raise Shopify::Pull::Failed, page.failures if page.failures.any?
    end

    private

    def changes_since
      synced_at = last_sync_at
      synced_at - CHANGES_OVERLAP if synced_at
    end

    def last_sync_at
      raise NotImplementedError, "#{self.class} must implement #last_sync_at"
    end

    def pull_class
      raise NotImplementedError, "#{self.class} must implement #pull_class"
    end

    def complete_pull(started_at:, updated_since:)
      stamp_sync(started_at) if started_at
      handle_terminal_page(updated_since:)
    end

    def stamp_sync(started_at)
      raise NotImplementedError, "#{self.class} must implement #stamp_sync"
    end

    def handle_terminal_page(updated_since:)
    end
  end
end
