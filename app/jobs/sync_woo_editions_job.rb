class SyncWooEditionsJob < ApplicationJob
  queue_as :default

  include Gettable
  include Sanitizable

  TYPES = Edition.types.values

  def perform(products_with_editions)
    woo_editions = get_editions(products_with_editions, "publish")
    parsed_woo_editions = parse(woo_editions)
    create(parsed_woo_editions)
  end

  def get_editions(products_with_editions, status)
    progress = 0
    total = products_with_editions.size
    products = Product.where(woo_id: products_with_editions)

    products_with_editions.map do |product_woo_id|
      progress += 1
      warn "\nGetting editions for product: #{product_woo_id}. Remaining: #{total - progress} products"

      next if products.find { |p| p.woo_id == product_woo_id.to_s }
        .editions.present?

      api_get(
        "https://store.handsomecake.com/wp-json/wc/v3/products/#{product_woo_id}/editions",
        status
      )
    end.flatten.compact_blank
  end

  def parse(woo_editions)
    woo_editions.map do |edition|
      result = {
        woo_id: edition[:id],
        product_woo_id: edition[:parent_id],
        store_link: edition[:permalink]
      }

      parsed_editions = edition[:attributes].each_with_object([]) do |attr, attrs|
        next attrs if attr[:option].blank?

        option = smart_titleize(sanitize(attr[:option]))

        if attr[:name].in? TYPES.flatten
          attrs << {
            type: attr[:name],
            value: option
          }
        end
      end

      result.merge(editions: parsed_editions)
    rescue => e
      Rails.logger.error "SyncWooEditionsJob. Error: #{e.message}"
      nil
    end
  end

  def create(parsed_woo_editions)
    parsed_woo_editions.each do |parsed_edition|
      next if parsed_edition.blank?

      product = Product.find_or_create_by(
        woo_id: parsed_edition[:product_woo_id]
      )

      create_edition(
        product:,
        edition_woo_id: parsed_edition[:woo_id],
        edition_types: parsed_edition[:editions],
        store_link: parsed_edition[:store_link]
      )
    end
  end

  def create_edition(
    product:,
    edition_woo_id:,
    edition_types:,
    store_link: nil
  )
    edition_types = [edition_types] if edition_types.is_a? Hash

    mapped_edition_types = edition_types.map do |edition_type|
      type_name = TYPES.find { |type|
        type.include? edition_type[:type]
      }.first.downcase

      if type_name == "Size"
        edition_type[:value] = Size.sanitize_size(edition_type[:value])
      end

      type_instance = type_name.capitalize.constantize.find_or_create_by({
        value: edition_type[:value]
      })

      product.send(:"product_#{type_name.pluralize}")
        .find_or_create_by({type_name => type_instance})

      {type_name => type_instance}
    end

    edition = Edition.find_or_initialize_by(woo_id: edition_woo_id)

    edition.assign_attributes({
      product:,
      store_link:
    }.merge(*mapped_edition_types).compact)

    edition.save

    edition
  end
end
