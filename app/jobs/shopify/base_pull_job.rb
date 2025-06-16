class Shopify::BasePullJob < ApplicationJob
  queue_as :default
  include Sanitizable

  def perform(attempts: 0, cursor: nil, limit: nil)
    fetch_shopify_data(cursor:, limit:)
    merge_new_items
    schedule_next_page(limit)
  rescue ShopifyAPI::Errors::HttpResponseError => e
    handle_api_error(e, attempts, cursor, limit)
  end

  private

  def fetch_shopify_data(cursor:, limit:)
    limit ||= batch_size
    api_client = Shopify::ApiClient.new
    @api_payload = api_client.pull(
      resource_name: resource_name,
      cursor:,
      batch_size: limit
    )
  end

  def merge_new_items
    @api_payload[:items].each do |api_item|
      parsed_item = parser_class.new(api_item:).parse
      creator_class.new(parsed_item:).update_or_create!
    end
  end

  def schedule_next_page(has_limit)
    if @api_payload[:has_next_page] && !has_limit
      self.class
        .set(wait: 1.second)
        .perform_later(cursor: @api_payload[:end_cursor])
    end
  end

  def handle_api_error(error, attempts, cursor, limit)
    if error.response.code == 429 # Rate limit error
      retry_delay = attempts * 5 + 5
      self.class
        .set(wait: retry_delay.seconds)
        .perform_later(attempts: attempts + 1, cursor:, limit:)
    else
      raise error
    end
  end

  def resource_name
    raise NotImplementedError, "#{self.class} must implement #resource_name"
  end

  def parser_class
    raise NotImplementedError, "#{self.class} must implement #parser_class"
  end

  def creator_class
    raise NotImplementedError, "#{self.class} must implement #creator_class"
  end

  def batch_size
    raise NotImplementedError, "#{self.class} must implement #batch_size"
  end
end
