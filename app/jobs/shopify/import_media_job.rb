# frozen_string_literal: true

module Shopify
  class ImportMediaJob < ApplicationJob
    queue_as :media

    def perform(product, parsed_media)
      product.import_shopify_media(parsed_media:)
    end
  end
end
