require "open-uri"

class SyncWooProductsJob < ApplicationJob
  queue_as :default

  include Gettable
  include Sanitizable

  URL = "https://store.handsomecake.com/wp-json/wc/v3/products/"
  STATUS = "publish"
  PRODUCTS_SIZE = 1300

  def perform
    parsed_products = parse_all(get_woo_products)
    create_all(parsed_products)
    get_products_with_variations(parsed_products)
  end

  def create_all(parsed_products)
    products = Product.where(woo_id: parsed_products.pluck(:woo_id))

    parsed_products.each do |parsed_product|
      next if products.find { |i| i.woo_id == parsed_product[:woo_id].to_s }
      create(parsed_product)
    end
  end

  def get_woo_products
    api_get_all(URL, PRODUCTS_SIZE, STATUS)
  end

  def create(parsed_product)
    return if parsed_product.blank?

    product = Product.find_or_initialize_by({
      title: parsed_product[:title],
      woo_id: parsed_product[:woo_id],
      franchise: Franchise.find_or_create_by(title: parsed_product[:franchise]),
      shape: Shape.find_or_create_by(title: parsed_product[:shape]),
      store_link: parsed_product[:store_link]
    })

    parsed_product[:brands]&.each do |i|
      if product.brands.find_by(title: i).nil?
        product.brands << Brand.find_or_create_by(title: i)
      end
    end

    parsed_product[:sizes]&.each do |i|
      if product.sizes.find_by(value: i).nil?
        product.sizes << Size.find_or_create_by(value: i)
      end
    end

    parsed_product[:versions]&.each do |i|
      if product.versions.find_by(value: i).nil?
        product.versions << Version.find_or_create_by(value: i)
      end
    end

    parsed_product[:colors]&.each do |i|
      if product.colors.find_by(value: i).nil?
        product.colors << Color.find_or_create_by(value: i)
      end
    end

    product.save
  end

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

  def parse(woo_product)
    return if woo_product[:name].blank?

    title, franchise, shape = parse_product_name(woo_product[:name])
    product = {
      woo_id: woo_product[:id],
      store_link: woo_product[:permalink],
      shape:,
      variations: woo_product[:variations],
      title:,
      franchise:,
      images: woo_product[:images].pluck(:src)
    }

    if woo_product[:attributes].present?
      attributes = woo_product[:attributes].map do |attr|
        attrs = {}
        options = attr[:options].map { |i| smart_titleize(sanitize(i)) }

        case attr[:name]
        when *Variation.types[:version]
          attrs[:versions] = options
        when *Variation.types[:size]
          attrs[:sizes] = options
        when *Variation.types[:color]
          attrs[:colors] = options
        when *Variation.types[:brand]
          attrs[:brands] = options
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

  def parse_all(woo_products)
    woo_products.map { |woo_product| parse(woo_product) }.compact_blank
  end

  def get_products_with_variations(parsed_products)
    parsed_products
      .select { |i| i[:variations].present? }
      .pluck(:woo_id)
  end

  def get_product(woo_id)
    woo_product = api_get(URL + woo_id.to_s, STATUS)
    parsed_product = parse(woo_product)

    return if parsed_product.blank?

    create(parsed_product)
  end
end
