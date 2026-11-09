# frozen_string_literal: true

class Sale::Woo::Pull
  ORDERS_SIZE = ENV["ORDERS_SIZE"] || 2700
  INFRASTRUCTURE_ERRORS = [
    ActiveRecord::ConnectionNotEstablished,
    ActiveRecord::QueryAborted,
    ActiveRecord::TransactionRollbackError,
    ActiveRecord::LockWaitTimeout
  ].freeze

  Failure = Data.define(:woo_id, :message)

  class Failed < StandardError
    REPORTED_FAILURES = 10

    attr_reader :failures

    def initialize(failures)
      @failures = failures
      details = failures.first(REPORTED_FAILURES).map { |failure| "#{failure.woo_id}: #{failure.message}" }
      super("#{failures.size} Woo order(s) failed to import: #{details.join("; ")}")
    end
  end

  attr_reader :limit, :pages, :id, :pulled_at
  private :limit, :pages, :id, :pulled_at

  def self.run(limit: nil, pages: nil, id: nil)
    new(limit:, pages:, id:).run
  end

  def initialize(limit:, pages:, id:)
    @limit = limit
    @pages = pages
    @id = id
    @pulled_at = Time.zone.now
  end

  def run
    failures = fetch_orders.filter_map { |order| failure_importing(order) }
    raise Failed, failures if failures.any?
  end

  private

  def fetch_orders
    client = Woo::Api::Client.new
    return [client.fetch_order(id)] if id.present?

    client.fetch_orders(limit || ORDERS_SIZE, pages)
  end

  def failure_importing(order)
    parsed_order = Sale::Woo::Parser.parse(order)
    Sale::Woo::Importer.import(parsed_order, pulled_at:) if parsed_order
    nil
  rescue *INFRASTRUCTURE_ERRORS
    raise
  rescue => error
    Rails.logger.error("Woo order #{order[:id]} failed to import: #{error.full_message(highlight: false)}")
    Failure.new(woo_id: order[:id], message: "#{error.class}: #{error.message}")
  end
end
