# frozen_string_literal: true

require "open-uri"

module Woo
  class PullProductsJob < ApplicationJob
    queue_as :default

    include Gettable
    include Sanitizable

    URL = "https://store.handsomecake.com/wp-json/wc/v3/products/"
    STATUS = "publish"
    PRODUCTS_SIZE = ENV["PRODUCTS_SIZE"] || 1400

    def perform
      parsed_products = parse_all(get_woo_products)
      create_all(parsed_products)
      get_products_with_variants(parsed_products)
    end

    def create_all(parsed_products)
      parsed_products.each do |parsed_product|
        create(parsed_product)
      end
    end

    def get_woo_products
      pages = nil
      api_get_all(URL, PRODUCTS_SIZE, pages, STATUS)
    end

    def create(parsed_product)
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

    def parse_all(woo_products)
      woo_products.map { |woo_product| parse(woo_product) }.compact_blank
    end

    def get_products_with_variants(parsed_products)
      parsed_products
        .select { |i| i[:variants].present? }
        .pluck(:woo_id)
    end

    def get_and_create_product(product_woo_id)
      woo_product = api_get(URL + product_woo_id.to_s, STATUS)
      parsed_product = parse(woo_product)

      return if parsed_product.blank?

      create(parsed_product)
    end
  end
end
