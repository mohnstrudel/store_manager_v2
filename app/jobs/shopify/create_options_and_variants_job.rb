# frozen_string_literal: true

module Shopify
  class CreateOptionsAndVariantsJob < ApplicationJob
    def perform(product_id, shopify_product_id)
      product = Product
        .includes(
          variants: [:color, :size, :version],
          product_colors: [:color],
          product_sizes: [:size],
          product_versions: [:version]
        )
        .find(product_id)
      client = Shopify::Api::Client.new

      shopify_option_names = existing_option_names(client, shopify_product_id)
      serialized_options = serialize_options(product, shopify_option_names)

      if serialized_options.any?
        options_response = client.create_product_options(shopify_product_id, serialized_options)

        update_options_shopify_info(product, options_response["options"])
        update_variants_shopify_info(product, options_response["variants"]["nodes"])
      end

      true
    end

    private

    def existing_option_names(client, shopify_product_id)
      selected_options = client.fetch_product(shopify_product_id)&.dig("variants", "edges", 0, "node", "selectedOptions")
      selected_options.to_a.pluck("name")
    end

    def serialize_options(product, shopify_option_names)
      {size: product.sizes, version: product.versions, color: product.colors}.filter_map do |type, collection|
        next if collection.none? || (Variant.shopify_types[type] & shopify_option_names).any?

        serialize_option(collection)
      end
    end

    def serialize_option(collection)
      option_name = collection.proxy_association.klass.name
      {
        name: option_name,
        values: collection.pluck(:value).map { |val| {name: val} }
      }
    end

    def update_options_shopify_info(product, shopify_options)
      shopify_options.each do |option|
        association_name = case option["name"]
        when "Color" then :product_colors
        when "Size" then :product_sizes
        when "Version" then :product_versions
        end

        next unless association_name

        option["optionValues"].each do |option_value|
          item = product.public_send(association_name).find { |product_ass|
            product_ass.public_send(option["name"].downcase).value == option_value["name"]
          }

          next unless item

          option_shopify_info = item.store_infos.find_or_initialize_by(store_name: :shopify)
          option_shopify_info.assign_attributes(
            store_id: option_value["id"],
            push_time: Time.current
          )
          option_shopify_info.save!
        end
      end
    end

    def update_variants_shopify_info(product, shopify_variants)
      shopify_variants.each do |shopify_variant|
        variant = find_variant_by_variant_options(product, shopify_variant["selectedOptions"])

        next unless variant

        variant_shopify_info = variant.store_infos.find_or_initialize_by(store_name: :shopify)
        variant_shopify_info.assign_attributes(
          store_id: shopify_variant["id"],
          push_time: Time.current
        )
        variant_shopify_info.save!
      end
    end

    def find_variant_by_variant_options(product, shopify_options)
      product.variants.find do |variant|
        shopify_options.all? do |option|
          case option["name"]
          when "Color"
            variant.color&.value == option["value"]
          when "Size"
            variant.size&.value == option["value"]
          when "Version"
            variant.version&.value == option["value"]
          end
        end
      end
    end
  end
end
