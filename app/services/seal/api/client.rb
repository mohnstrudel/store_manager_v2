# frozen_string_literal: true

# Seal::Api::Client
#
# For looking up Seal Subscriptions data (https://www.sealsubscriptions.com) via
# its Merchant REST API. Used to resolve which real product/order an installment
# ("Subsequent Subscription Order") payment belongs to, when that can't be
# determined from our own data.
#
# Seal's API has no endpoint to look up a subscription by Shopify order ID
# directly, so this indexes every subscription's origin order and billing
# attempts by order ID on first use. Reuse a single instance across a batch of
# lookups (e.g. one import run or one backfill pass) so that index is only
# built once.
#
# Usage:
#   client = Seal::Api::Client.new
#   client.find_subscription_for_order("gid://shopify/Order/123")
module Seal
  module Api
    class Client
      class ApiError < StandardError; end

      BASE_URL = "https://app.sealsubscriptions.com/shopify/merchant/api/"
      TOKEN = Rails.application.credentials.dig(:seal_subscriptions, :token) || ENV.fetch("SEAL_SUBSCRIPTIONS_API_TOKEN", "")
      PER_PAGE = 50

      class << self
        # A shared instance so the order index (built by paginating every
        # subscription) is only fetched once per process, not once per lookup.
        def shared
          @shared ||= new
        end
      end

      # Finds the subscription whose origin order or a billing attempt matches
      # the given Shopify order ID (accepts a GID or a plain numeric ID).
      #
      # @param order_id [String] The Shopify order ID (GID or numeric)
      # @return [Hash, nil] The subscription data, or nil if none matches
      def find_subscription_for_order(order_id)
        numeric_id = Sale::Shopify::OrderId.normalize(order_id)
        return nil if numeric_id.blank?

        order_index[numeric_id]
      end

      def each_subscription_detail
        return enum_for(__method__) unless block_given?

        each_subscription do |subscription|
          yield fetch_subscription_detail(subscription.fetch("id"))
        end
      end

      def selling_plans_by_id
        each_subscription_rule.each_with_object({}) do |rule, plans|
          Array(rule["selling_plans"]).each do |selling_plan|
            selling_plan_id = selling_plan["selling_plan_id"].to_s
            plans[selling_plan_id] = selling_plan if selling_plan_id.present?
          end
        end
      end

      private

      def order_index
        @order_index ||= build_order_index
      end

      def build_order_index(index = {})
        each_subscription do |subscription|
          order_ids_for(subscription).each { |order_id| index[order_id] ||= subscription }
        end
        index
      end

      def order_ids_for(subscription)
        billing_attempt_order_ids = Array(subscription["billing_attempts"]).filter_map { |attempt| attempt["order_id"]&.to_s }
        [subscription["order_id"]&.to_s, *billing_attempt_order_ids].compact
      end

      def each_subscription
        page = 1

        loop do
          subscriptions = fetch_subscriptions_page(page)
          break if subscriptions.blank?

          subscriptions.each { |subscription| yield subscription }
          break if subscriptions.size < PER_PAGE

          page += 1
        end
      end

      def fetch_subscriptions_page(page)
        response = get("subscriptions", page:, "with-items": true, "with-billing-attempts": true)
        payload = response["payload"] || response
        Array(payload["subscriptions"])
      end

      def fetch_subscription_detail(id)
        response = get("subscription", id:)
        response["payload"] || response
      end

      def each_subscription_rule
        return enum_for(__method__) unless block_given?

        page = 1

        loop do
          response = get("subscription-rules", page:)
          payload = response["payload"] || response
          rules = Array(payload["subscription_rules"])
          rules.each { |rule| yield rule }
          break if page >= payload["total_pages"].to_i

          page += 1
        end
      end

      def get(path, query = {})
        response = HTTParty.get(
          "#{BASE_URL}#{path}",
          query: query.compact,
          headers: {"X-Seal-Token" => TOKEN}
        )

        raise ApiError, "Seal API GET #{path} failed: HTTP #{response.code}" unless response.success?

        JSON.parse(response.body)
      rescue HTTParty::Error, JSON::ParserError => e
        raise ApiError, "Seal API GET #{path} failed: #{e.class}: #{e.message}"
      end
    end
  end
end
