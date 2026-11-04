# frozen_string_literal: true

class Product::Woo::Importer
  OPTION_ASSOCIATIONS = {
    brands: [Brand, :title],
    sizes: [Size, :value],
    versions: [Version, :value],
    colors: [Color, :value]
  }.freeze

  attr_reader :parsed_product, :product
  private :parsed_product, :product

  def self.fetch_and_import(woo_id, client: ::Woo::Api::Client.new)
    parsed_product = Product::Woo::Parser.parse(client.fetch_product(woo_id))

    return if parsed_product.blank?

    import(parsed_product)
  end

  def self.import(parsed_product)
    return if parsed_product.blank?

    new(parsed_product).import
  end

  def initialize(parsed_product)
    @parsed_product = parsed_product
  end

  def import
    @product = Product.find_by_woo_id(parsed_product[:woo_id]) || Product.new
    product.assign_attributes(
      title: parsed_product[:title],
      franchise: Franchise.find_or_create_by(title: parsed_product[:franchise]),
      shape: parsed_product[:shape].presence || Product.default_shape
    )
    OPTION_ASSOCIATIONS.each { |association, (model, attribute)| add_options(association, model, attribute) }
    product.save!
    record_store_info
    product
  end

  private

  def add_options(association, model, attribute)
    parsed_product[association]&.each do |value|
      if product.public_send(association).find_by(attribute => value).nil?
        product.public_send(association) << model.find_or_create_by(attribute => value)
      end
    end
  end

  def record_store_info
    product.update_or_create_store_info(
      store_name: :woo,
      store_id: parsed_product[:woo_id],
      slug: parsed_product[:store_link],
      pull_time: Time.zone.now
    )
  end
end
