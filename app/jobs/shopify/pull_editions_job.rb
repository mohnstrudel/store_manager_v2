# frozen_string_literal: true

module Shopify
  class PullEditionsJob < ApplicationJob
    def perform(product, parsed_editions)
      parsed_editions.each do |parsed_edition|
        Edition::ShopifyImporter.import!(product, parsed_edition)
      end
    end
  end
end
