# frozen_string_literal: true

module Size::Parsing
  extend ActiveSupport::Concern

  class_methods do
    def parse_size(product_title)
      num_sizes = product_title.scan(numeric_size_match).flatten

      return if num_sizes.blank?

      sizes = num_sizes.map { |size| size.tr("/", ":") }
      return sizes.first if sizes.length == 1

      sizes
    end

    def sanitize_size(product_title)
      num_size = product_title.match(numeric_size_match)
      converted_title = num_size[0].tr("/", ":") if num_size.present?

      if converted_title
        product_title.sub(num_size[0], converted_title)
      else
        product_title
      end
    end

    def numeric_size_match
      # 1:2, 1:3, 1:4, 1:5, 1:6, 1:3.5, 1:1, 1:7, 1:10
      # and 1/2, 1/3, etc.
      /(1[\/:](?:[2-9]|3\.5|10?))/
    end
  end
end
