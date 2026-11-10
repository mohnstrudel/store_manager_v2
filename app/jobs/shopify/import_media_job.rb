# frozen_string_literal: true

module Shopify
  class ImportMediaJob < ApplicationJob
    STATUS_EXPIRATION = 10.minutes.to_i

    queue_as :media

    def perform(product, parsed_media, force: false)
      product.import_shopify_media(parsed_media:, force:)
    end

    def expiration
      STATUS_EXPIRATION
    end
  end
end
