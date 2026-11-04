# frozen_string_literal: true

class Product::Woo::Parser
  include Sanitizable

  attr_reader :woo_product
  private :woo_product

  def self.parse(woo_product)
    return if woo_product.blank?

    return if woo_product[:name].blank?

    new(woo_product).parse
  end

  def initialize(woo_product)
    @woo_product = woo_product
  end

  def parse
    title, franchise, shape = parse_product_name
    product = {
      woo_id: woo_product[:id],
      store_link: woo_product[:permalink],
      shape:,
      variants: woo_product[:variants] || woo_product[:editions],
      title:,
      franchise:,
      images: woo_product[:images].pluck(:src)
    }

    product = product.merge(*parse_attributes) if woo_product[:attributes].present?

    if product[:brands].nil?
      brand_title = Brand.parse_brand(woo_product[:name])
      product[:brands] = [brand_title] if brand_title
    end

    product
  end

  private

  def parse_product_name
    woo_name = smart_titleize(sanitize(woo_product[:name]))
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

  def parse_attributes
    woo_product[:attributes].map { |attr| parse_attribute(attr) }.compact.reject(&:empty?)
  end

  def parse_attribute(attr)
    options = attr[:options].presence || [attr[:option]]
    values = options.map { |i| smart_titleize(sanitize(i)) }

    case attr[:name]
    when *::Variant.types[:version]
      {versions: values}
    when *::Variant.types[:size]
      {sizes: values}
    when *::Variant.types[:color]
      {colors: values}
    when *::Variant.types[:brand]
      {brands: values}
    else
      {}
    end
  end
end
