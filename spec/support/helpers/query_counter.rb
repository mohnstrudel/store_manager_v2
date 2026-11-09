# frozen_string_literal: true

module Helpers
  module QueryCounter
    IGNORED_QUERY_NAMES = %w[SCHEMA TRANSACTION].freeze

    def count_queries(&)
      capture_queries(&).size
    end

    def capture_queries
      statements = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        next if payload[:cached] || IGNORED_QUERY_NAMES.include?(payload[:name])

        statements << payload[:sql]
      end

      yield
      statements
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end
end
