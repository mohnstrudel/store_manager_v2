# frozen_string_literal: true

module Shopify
  class PullMediaJob < ApplicationJob
    def perform(product_id, parsed_media)
      Product::Shopify::Media::Pull.call(product_id:, parsed_media:)
    end
  end
end
