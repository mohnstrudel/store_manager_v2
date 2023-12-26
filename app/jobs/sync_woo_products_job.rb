class SyncWooProductsJob < ApplicationJob
  queue_as :default

  include Gettable

  URL = "https://store.handsomecake.com/wp-json/wc/v3/products/"
  STATUS = "publish"
  PRODUCTS_SIZE = 1200

  def perform
    woo_products = api_get_all(URL, PRODUCTS_SIZE, STATUS)
    parsed_products = parse_all(woo_products)
    create_all(parsed_products)
    get_products_with_variations(parsed_products)
  end

  def create_all(parsed_products)
    parsed_products.each do |parsed_product|
      create(parsed_product)
    end
  end

  def create(parsed_product)
    product = Product.new({
      title: parsed_product[:title],
      woo_id: parsed_product[:woo_id],
      franchise: Franchise.find_or_create_by(title: parsed_product[:franchise]),
      shape: Shape.find_or_create_by(title: parsed_product[:shape]),
      image: parsed_product[:image],
      store_link: parsed_product[:store_link]
    })
    parsed_product[:brands]&.each do |i|
      product.brands << Brand.find_or_create_by(title: i)
    end
    parsed_product[:sizes]&.each do |i|
      product.sizes << Size.find_or_create_by(value: i)
    end
    parsed_product[:versions]&.each do |i|
      product.versions << Version.find_or_create_by(value: i)
    end
    parsed_product[:colors]&.each do |i|
      product.colors << Color.find_or_create_by(value: i)
    end
    product.save
  end

  def parse_product_name(woo_product_name)
    woo_name = sanitize(woo_product_name)
    franchise = woo_name.include?(" - ") ?
      woo_name.split(" - ").first :
      woo_name.split(" | ").first
    if franchise.blank?
      franchise = woo_product_name
    end
    title = woo_name.include?(" - ") ?
      woo_name.split(" | ").first.split(" - ").last :
      franchise
    shape = woo_name.match(/\b(bust|statue)\b/i) || ["Statue"]
    [title, franchise, shape]
  end

  def parse(woo_product)
    return if woo_product[:name].blank?
    title, franchise, shape = parse_product_name(woo_product[:name])
    image = woo_product[:images].present? ?
      woo_product[:images].first[:src] :
      ""
    product = {
      woo_id: woo_product[:id],
      store_link: woo_product[:permalink],
      shape: shape[0],
      variations: woo_product[:variations],
      title:,
      franchise:,
      image:
    }
    if woo_product[:attributes].present?
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
    else
      product
    end
  end

  def parse_all(woo_products)
    # We use .compact because we can get nil values from the parser
    # This is because the Woo DB has not been harmonized
    woo_products.map { |woo_product| parse(woo_product) }.compact
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

  private

  def sanitize(string)
    string.tr(" ", " ").gsub(/—|–/, "-").gsub("&amp;", "&").split("|").map { |s| s.strip }.join(" | ")
  end
end
