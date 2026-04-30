# frozen_string_literal: true

module Woo
  class PullVariantsJob < ApplicationJob
    queue_as :default

    include Gettable
    include Sanitizable

    TYPES = ::Variant.types.values

    def perform(products_with_variants)
      variants_api_response = get_variants(products_with_variants, "publish")
      parsed_woo_variants = parse(variants_api_response)
      create(parsed_woo_variants)
    end

    def get_variants(products_with_variants, status)
      progress = 0
      total = products_with_variants.size
      products = Product.where_woo_ids(products_with_variants)

      products_with_variants.map do |product_woo_id|
        progress += 1
        warn "\nGetting variants for product: #{product_woo_id}. Remaining: #{total - progress} products"

        next if products.find { |p| p.woo_store_id == product_woo_id.to_s }
          .variants.present?

        api_get(
          "https://store.handsomecake.com/wp-json/wc/v3/products/#{product_woo_id}/editions",
          status
        )
      end.flatten.compact_blank
    end

    def parse(variants_api_response)
      variants_api_response.map { Woo::Variant.deserialize(it) }.compact
    end

    def create(parsed_variants_api_response)
      parsed_variants_api_response.each { Woo::Variant.import(it) }
    end

    def create_variant(
      product:,
      variant_woo_id:,
      variant_types:,
      store_link: nil
    )
      Woo::Variant.import(
        woo_id: variant_woo_id,
        product_woo_id: product.woo_store_id,
        store_link: store_link,
        options: variant_types
      )
      variant_types = [variant_types] if variant_types.is_a? Hash

      mapped_variant_types = variant_types.map do |variant_type|
        # type_name == "size", "version" or "color"
        type_name = TYPES.find { |type|
          type.include? variant_type[:type]
        }&.first&.downcase

        if type_name == "Size"
          variant_type[:value] = Size.sanitize_size(variant_type[:value])
        end

        next if type_name.blank?

        type_instance = type_name.capitalize.constantize.find_or_create_by({
          value: variant_type[:value]
        })

        begin
          # e.g. product.send(:product_sizes).find_or_create_by!({size: #<Size id: 5, value: "1:43">})
          product.send(:"product_#{type_name.pluralize}")
            .find_or_create_by!({type_name => type_instance})
        rescue ActiveRecord::RecordNotUnique
          product.send(:"product_#{type_name.pluralize}")
            .find_by!({type_name => type_instance})
        end

        {type_name => type_instance}
      end

      variant = ::Variant.find_by_woo_id(variant_woo_id) || ::Variant.new

      variant.assign_attributes({
        product:
      }.merge(*mapped_variant_types).compact)

      variant.save

      if store_link.present?
        woo_info = variant.woo_info || variant.store_infos.woo.new
        if woo_info.persisted?
          woo_info.update(slug: store_link)
        else
          woo_info.slug = store_link
          woo_info.save!
        end
      end

      variant
    end
  end
end
