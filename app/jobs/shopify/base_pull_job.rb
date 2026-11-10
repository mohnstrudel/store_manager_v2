# frozen_string_literal: true

module Shopify
  class BasePullJob < Shopify::ApiJob
    include NotifiesRequester

    CHANGES_OVERLAP = 15.minutes

    queue_as :default
    sidekiq_options retry: false
    discard_on(Shopify::Pull::Failed) { |_job, error| Sentry.capture_exception(error) }

    def perform(changes_only: false, cursor: nil, started_at: nil, updated_since: nil, failed_count: 0, requested_by: nil)
      if cursor.nil?
        started_at = Time.current
        updated_since = changes_since if changes_only
      end

      page = pull_class.page(cursor:, updated_since:)
      failed_count += page.failures.size

      if page.next_cursor
        self.class.perform_later(cursor: page.next_cursor, started_at:, updated_since:, **{requested_by:, failed_count: failed_count.nonzero?}.compact)
      else
        complete_pull(started_at:, updated_since:, failed_count:)
        notify_requester_of_outcome(failed_count, page.failures)
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

    def complete_pull(started_at:, updated_since:, failed_count:)
      stamp_sync(started_at) if started_at && (failed_count.zero? || stamp_past_failures?)
      handle_terminal_page(updated_since:)
    end

    def stamp_past_failures?
      true
    end

    def stamp_sync(started_at)
      raise NotImplementedError, "#{self.class} must implement #stamp_sync"
    end

    def handle_terminal_page(updated_since:)
    end

    def notify_requester_of_outcome(failed_count, failures)
      if failed_count.zero?
        notify_requester_of_success("#{job_title} finished.")
      else
        notify_requester_of_failure(Shopify::Pull::Failed.new(failures, total: failed_count))
      end
    end

    def job_title
      raise NotImplementedError, "#{self.class} must implement #job_title"
    end

    def notify_requester_of_discard(error)
      super unless error.is_a?(Shopify::Pull::Failed)
    end
  end
end
