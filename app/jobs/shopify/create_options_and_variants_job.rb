class Shopify::CreateOptionsAndVariantsJob < ApplicationJob
  def perform(product_id, shopify_product_id)
    product = Product.find(product_id)
    api_client = Shopify::ApiClient.new

    serialized_options = serialize_options(product)

    if serialized_options.any?
      options_response = api_client.create_product_options(shopify_product_id, serialized_options)

      update_options_shopify_info(product, options_response["options"])
      update_editions_shopify_info(product, options_response["variants"]["nodes"])
    end

    true
  end

  private

  def serialize_options(product)
    options = []

    options << serialize_option(product.sizes) if product.sizes.any?
    options << serialize_option(product.versions) if product.versions.any?
    options << serialize_option(product.colors) if product.colors.any?

    options
  end

  def serialize_option(collection)
    # e.g. "Color", "Size", "Version"
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
        # We're getting product options through associations:
        # e.g. product.product_colors.find { |pc| pc.color.value == option_value["name"] }
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

  def update_editions_shopify_info(product, shopify_variants)
    shopify_variants.each do |variant|
      edition = find_edition_by_variant_options(product, variant["selectedOptions"])

      next unless edition

      edition_shopify_info = edition.store_infos.find_or_initialize_by(store_name: :shopify)
      edition_shopify_info.assign_attributes(
        store_id: variant["id"],
        push_time: Time.current
      )
      edition_shopify_info.save!
    end
  end

  def find_edition_by_variant_options(product, shopify_options)
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
