class Shopify::CreateProductJob < ApplicationJob
  def perform(product_id)
    product = Product.find(product_id)
    serialized_product = Shopify::ProductSerializer.serialize(product)

    if serialized_product.present?
      api_client = Shopify::ApiClient.new

      product_shopify_info = product.store_infos.find_or_initialize_by(store_name: :shopify)

      product_response = api_client.create_product(serialized_product)
      shopify_product_id = product_response["id"]

      product_shopify_info.assign_attributes(
        push_time: Time.current,
        store_id: shopify_product_id,
        slug: product_response["handle"]
      )
      product_shopify_info.save

      if product.sizes.any? || product.versions.any? || product.colors.any?
        serialized_options = serialize_options(product, shopify_product_id)

        options_response = api_client.create_product_options(shopify_product_id, serialized_options)

        update_options_shopify_info(product, options_response["options"])
        update_editions_shopify_info(product, options_response["variants"]["nodes"])
      end

      true
    end
  end

  private

  def serialize_options(product, shopify_product_id)
    options = []

    options << serialize_option(product.sizes) if product.sizes.any?
    options << serialize_option(product.versions) if product.versions.any?
    options << serialize_option(product.colors) if product.colors.any?

    options
  end

  def serialize_option(collection)
    {
      name: collection.class_name,
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
        # We're getting product options through associations:
        # e.g. product.product_colors.find { |pc| pc.color.value == option_value["name"] }
        item = product.public_send(association_name).find { |product_ass|
          product_ass.public_send(option["name"].downcase).value == option_value["name"]
        }

        next unless item

        shopify_info = item.store_infos.find_or_initialize_by(store_name: :shopify)
        shopify_info.save(
          store_id: option_value["id"],
          push_time: Time.current
        )
      end
    end
  end

  def update_editions_shopify_info(product, shopify_variants)
    shopify_variants.each do |variant|
      edition = find_edition_by_options(product, variant["selectedOptions"])
      shopify_info = edition.store_infos.find_or_initialize_by(store_name: :shopify)
      shopify_info.save(
        store_id: variant["id"],
        push_time: Time.current
      )
    end
  end

  def find_edition_by_options(product, shopify_options)
    editions = product.editions.includes(:color, :size, :version)

    editions.find do |edition|
      shopify_options.all? do |option|
        case option["name"]
        when "Color"
          edition.color&.value == option["value"]
        when "Size"
          edition.size&.value == option["value"]
        when "Version"
          edition.version&.value == option["value"]
        end
      end
    end
  end
end
