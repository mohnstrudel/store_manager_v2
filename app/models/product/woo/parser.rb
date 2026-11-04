# frozen_string_literal: true

class Product::Woo::Parser
  include Sanitizable

  class << self
    def parse_all(woo_products)
      woo_products.map { |woo_product| parse(woo_product) }.compact_blank
    end

    def parse(woo_product)
      return if woo_product.blank?

      return if woo_product[:name].blank?

      title, franchise, shape = parse_product_name(woo_product[:name])
      product = {
        woo_id: woo_product[:id],
        store_link: woo_product[:permalink],
        shape:,
        variants: woo_product[:variants] || woo_product[:editions],
        title:,
        franchise:,
        images: woo_product[:images].pluck(:src)
      }

      if woo_product[:attributes].present?
        attributes = woo_product[:attributes].map do |attr|
          attrs = {}
          options = attr[:options].presence || [attr[:option]]
          values = options.map { |i| smart_titleize(sanitize(i)) }

          case attr[:name]
          when *::Variant.types[:version]
            attrs[:versions] = values
          when *::Variant.types[:size]
            attrs[:sizes] = values
          when *::Variant.types[:color]
            attrs[:colors] = values
          when *::Variant.types[:brand]
            attrs[:brands] = values
          end

          attrs
        end

        product = product.merge(*attributes.compact.reject(&:empty?))
      end

      if product[:brands].nil?
        brand_title = Brand.parse_brand(woo_product[:name])
        product[:brands] = [brand_title] if brand_title
      end

      product
    end

    private

    def parse_product_name(woo_product_name)
      woo_name = smart_titleize(sanitize(woo_product_name))
        .sub(Size.numeric_size_match, "")

      franchise = woo_name.include?(" - ") ?
        woo_name.split(" - ").first :
        woo_name.split(" | ").first

      if franchise.blank?
        franchise = woo_name
      end

      title = woo_name.include?(" - ") ?
        woo_name.split(" | ").first.split(" - ").last :
        franchise

      shape = woo_name.match(/\b(bust|statue)\b/i) || ["Statue"]

      [title, franchise, smart_titleize(shape[0])]
    end
  end
end
