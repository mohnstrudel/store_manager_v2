# frozen_string_literal: true

class Product::Shopify::OptionsPush
  attr_reader :product, :product_store_id, :client
  private :product, :product_store_id, :client

  def self.call(product_id:, product_store_id:)
    new(product_id:, product_store_id:).call
  end

  def initialize(product_id:, product_store_id:)
    @product = Product
      .includes(
        variants: [:color, :size, :version],
        product_colors: [:color],
        product_sizes: [:size],
        product_versions: [:version]
      )
      .find(product_id)
    @product_store_id = product_store_id
    @client = ::Shopify::Api::Client.new
  end

  def call
    serialized_options = serialize_options(existing_option_names)

    if serialized_options.any?
      options_response = client.create_product_options(product_store_id, serialized_options)

      update_options_shopify_info(options_response["options"])
      update_variants_shopify_info(options_response["variants"]["nodes"])
    end

    true
  end

  private

  def serialize_options(shopify_option_names)
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

  def existing_option_names
    selected_options = client.fetch_product(product_store_id)&.dig("variants", "edges", 0, "node", "selectedOptions")
    selected_options.to_a.pluck("name")
  end

  def update_options_shopify_info(shopify_options)
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

  def update_variants_shopify_info(shopify_variants)
    shopify_variants.each do |shopify_variant|
      variant = find_variant_by_variant_options(shopify_variant["selectedOptions"])

      next unless variant

      variant_shopify_info = variant.store_infos.find_or_initialize_by(store_name: :shopify)
      variant_shopify_info.assign_attributes(
        store_id: shopify_variant["id"],
        push_time: Time.current
      )
      variant_shopify_info.save!
    end
  end

  def find_variant_by_variant_options(shopify_options)
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
