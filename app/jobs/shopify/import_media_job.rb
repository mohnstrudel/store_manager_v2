# frozen_string_literal: true

module Shopify
  class ImportMediaJob < ApplicationJob
    def perform(product, parsed_media)
      return if product.blank?

      product.import_shopify_media(parsed_media:)
    end
  end
end
