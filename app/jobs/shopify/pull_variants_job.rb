# frozen_string_literal: true

module Shopify
  class PullVariantsJob < ApplicationJob
    def perform(product, parsed_variants)
      Variant::Shopify::Importer.import_all!(product, parsed_variants)
    end
  end
end
