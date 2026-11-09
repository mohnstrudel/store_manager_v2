# frozen_string_literal: true

class Shopify::Pull
  Page = Data.define(:imported_count, :next_cursor, :failures)
  Failure = Data.define(:store_id, :message, :failed_at)

  class Failed < StandardError
    REPORTED_FAILURES = 10

    attr_reader :failures

    def initialize(failures)
      @failures = failures
      details = failures.first(REPORTED_FAILURES).map { |failure| "#{failure.store_id}: #{failure.message}" }
      super("#{failures.size} Shopify item(s) failed to import: #{details.join("; ")}")
    end
  end

  def self.page(cursor: nil, updated_since: nil)
    new.page(cursor:, updated_since:)
  end

  def page(cursor:, updated_since:)
    payload = fetch(Shopify::Api::Client.new, cursor:, batch_size:, updated_since:)
    failures = []
    imported_count = payload[:items].count { |item| import(item, failures) }

    Page.new(imported_count:, next_cursor: (payload[:end_cursor] if payload[:has_next_page]), failures:)
  end

  private

  def fetch(api_client, cursor:, batch_size:, updated_since:)
    raise NotImplementedError, "#{self.class} must implement #fetch"
  end

  def batch_size
    raise NotImplementedError, "#{self.class} must implement #batch_size"
  end

  def import(item, failures)
    importer_class.import(parser_class.parse(item))
    true
  rescue *skippable_errors => error
    failures << Failure.new(store_id: item["id"], message: error.message, failed_at: Time.current)
    false
  end

  def importer_class
    raise NotImplementedError, "#{self.class} must implement #importer_class"
  end

  def parser_class
    raise NotImplementedError, "#{self.class} must implement #parser_class"
  end

  def skippable_errors
    []
  end
end
