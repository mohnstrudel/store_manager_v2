# frozen_string_literal: true

module Woo
  class PullProductsJob < ApplicationJob
    queue_as :default

    PRODUCTS_SIZE = ENV["PRODUCTS_SIZE"] || 1400

    def perform
      parsed_products = Product::Woo::Parser.parse_all(Woo::Api::Client.new.fetch_products(PRODUCTS_SIZE))
      parsed_products.each { |parsed_product| Product::Woo::Importer.import!(parsed_product) }
      parsed_products.select { |parsed_product| parsed_product[:variants].present? }.pluck(:woo_id)
    end
  end
end
