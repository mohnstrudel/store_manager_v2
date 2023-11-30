class SyncWooProductsJob < ApplicationJob
  queue_as :default

  include Gettable

  URL = "https://store.handsomecake.com/wp-json/wc/v3/products/"
  PRODUCTS_SIZE = 1200

  def perform
    woo_products = api_get_all(URL, PRODUCTS_SIZE, "publish")
    parsed_products = parse_woo_products(woo_products)
    create(parsed_products)
    get_products_with_variations(parsed_products)
  end

  def create(parsed_products)
    parsed_products.each do |woo_product|
      product = Product.new({
        title: woo_product[:title],
        woo_id: woo_product[:woo_id],
        franchise: Franchise.find_or_create_by(title: woo_product[:franchise]),
        shape: Shape.find_or_create_by(title: woo_product[:shape]),
        image: woo_product[:image],
        store_link: woo_product[:store_link]
      })
      woo_product[:brands]&.each do |i|
        product.brands << Brand.find_or_create_by(title: i)
      end
      woo_product[:sizes]&.each do |i|
        product.sizes << Size.find_or_create_by(value: i)
      end
      woo_product[:versions]&.each do |i|
        product.versions << Version.find_or_create_by(value: i)
      end
      woo_product[:colors]&.each do |i|
        product.colors << Color.find_or_create_by(value: i)
      end
      product.save!
    end
  end

  def parse_woo_product(woo_product)
    return if woo_product[:attributes].blank?
    woo_name = sanitize(woo_product[:name])
    franchise = woo_name.include?(" - ") ? woo_name.split(" - ").first : woo_name.split(" | ").first
    title = woo_name.include?(" - ") ? woo_name.split(" | ").first.split(" - ").last : franchise
    shape = woo_name.match(/\b(bust|statue)\b/i)
    image = woo_product[:images].present? ? woo_product[:images].first[:src] : ""
    product = {
      woo_id: woo_product[:id],
      store_link: woo_product[:permalink],
      shape: shape.present? && shape[0],
      variations: woo_product[:variations],
      title:,
      franchise:,
      image:
    }
    attributes = woo_product[:attributes].map do |attr|
      attrs = {}
      options = attr[:options].map(&method(:sanitize))
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
    product.merge(*attributes.compact.reject(&:empty?))
  end

  def parse_woo_products(woo_products)
    # We use .compact because we can get nil values from the parser:
    # It returns them if woo_product[:attributes].blank?
    # This is because the Woo DB has not been harmonized
    woo_products.map { |i| parse_woo_product(i) }.compact
  end

  def get_products_with_variations(parsed_products)
    parsed_products.select { |i| i[:variations].present? }.pluck(:woo_id)
  end

  private

  def sanitize(string)
    string.tr(" ", " ").gsub(/—|–/, "-").gsub("&amp;", "&").split("|").map { |s| s.strip }.join(" | ")
  end
end
