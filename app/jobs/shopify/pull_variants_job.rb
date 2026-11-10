# frozen_string_literal: true

module Shopify
  class PullVariantsJob < ApplicationJob
    STATUS_EXPIRATION = 10.minutes.to_i

    def perform(product, parsed_variants)
      Variant::Shopify::Importer.import_all(product, parsed_variants)
    end

    def expiration
      STATUS_EXPIRATION
    end
  end
end
