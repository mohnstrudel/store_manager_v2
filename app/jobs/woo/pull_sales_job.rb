# frozen_string_literal: true

module Woo
  class PullSalesJob < ApplicationJob
    queue_as :default

    ORDERS_SIZE = ENV["ORDERS_SIZE"] || 2700

    def perform(limit: nil, pages: nil, id: nil)
      client = Woo::Api::Client.new
      woo_orders = if id.present?
        [client.fetch_order(id)]
      else
        client.fetch_orders(limit || ORDERS_SIZE, pages)
      end

      Sale::Woo::Importer.import_all!(Sale::Woo::Parser.parse_all(woo_orders))
      nil
    end
  end
end
