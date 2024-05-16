class SyncWooVariationsJob < ApplicationJob
  queue_as :default

  include Gettable
  include Sanitizable

  TYPES = Variation.types.values

  def perform(products_with_variations)
    woo_variations = get_variations(products_with_variations, "publish")
    parsed_woo_variations = parse(woo_variations)
    create(parsed_woo_variations)
  end

  def get_variations(products_with_variations, status)
    progress = 0
    total = products_with_variations.size
    products = Product.where(woo_id: products_with_variations)

    products_with_variations.map do |product_woo_id|
      progress += 1
      warn "\nGetting variations for product: #{product_woo_id}. Remaining: #{total - progress} products"

      next if products.find { |p| p.woo_id == product_woo_id.to_s }
        .variations.present?

      api_get(
        "https://store.handsomecake.com/wp-json/wc/v3/products/#{product_woo_id}/variations",
        status
      )
    end.flatten.compact_blank
  end

  def parse(woo_variations)
    woo_variations.map do |variation|
      result = {
        woo_id: variation[:id],
        product_woo_id: variation[:parent_id],
        store_link: variation[:permalink]
      }

      parsed_variations = variation[:attributes].each_with_object([]) do |attr, attrs|
        next attrs if attr[:option].blank?

        option = smart_titleize(sanitize(attr[:option]))

        if attr[:name].in? TYPES.flatten
          attrs << {
            type: attr[:name],
            value: option
          }
        end
      end

      result.merge(variations: parsed_variations)
    rescue => e
      Rails.logger.error "SyncWooVariationsJob. Error: #{e.message}"
      nil
    end
  end

  def create(parsed_woo_variations)
    parsed_woo_variations.each do |parsed_variation|
      next if parsed_variation.blank?

      product = Product.find_or_create_by(
        woo_id: parsed_variation[:product_woo_id]
      )

      create_variation(
        product:,
        variation_woo_id: parsed_variation[:woo_id],
        variation_types: parsed_variation[:variations],
        store_link: parsed_variation[:store_link]
      )
    end
  end

  def create_variation(
    product:,
    variation_woo_id:,
    variation_types:,
    store_link: nil
  )
    variation_types = [variation_types] if variation_types.is_a? Hash

    mapped_variation_types = variation_types.map do |variation_type|
      type_name = TYPES.find do |type|
        type.include? variation_type[:type]
      end.first

      if type_name == "Size"
        variation_type[:value] = Size.parse_size(variation_type[:value])
      end

      type_instance = type_name.constantize.find_or_create_by({
        value: variation_type[:value]
      })

      product.send(:"product_#{type_name.downcase.pluralize}")
        .find_or_create_by({type_name.downcase => type_instance})

      {type_name.downcase => type_instance}
    end

    Variation.find_by(woo_id: variation_woo_id).presence ||
      Variation.create({
        product:,
        store_link:,
        woo_id: variation_woo_id
      }.merge(*mapped_variation_types).compact)
  end
end
