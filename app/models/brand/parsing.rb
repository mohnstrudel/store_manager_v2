# frozen_string_literal: true

module Brand::Parsing
  extend ActiveSupport::Concern

  class_methods do
    def parse_brand(product_title)
      product_title = smart_titleize(sanitize(product_title))
      brand_identifier = product_title.match(/(?:vo[nm]|by)\s+(.+)/i)
      brand_identifier[1] if brand_identifier.present?
    end
  end
end
