# frozen_string_literal: true

class Product::Woo::Importer
  class << self
    def fetch_and_import(woo_id, client: ::Woo::Api::Client.new)
      parsed_product = Product::Woo::Parser.parse(client.fetch_product(woo_id))

      return if parsed_product.blank?

      import!(parsed_product)
    end

    def import!(parsed_product)
      return if parsed_product.blank?

      product = Product.find_by_woo_id(parsed_product[:woo_id]) || Product.new
      product.assign_attributes(
        title: parsed_product[:title],
        franchise: Franchise.find_or_create_by(title: parsed_product[:franchise]),
        shape: parsed_product[:shape].presence || Product.default_shape
      )

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

      product.save!

      product.update_or_create_store_info!(
        store_name: :woo,
        store_id: parsed_product[:woo_id],
        slug: parsed_product[:store_link],
        pull_time: Time.zone.now
      )

      product
    end
  end
end
