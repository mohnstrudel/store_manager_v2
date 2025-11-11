class SyncWooEditionsJob < ApplicationJob
  queue_as :default

  include Gettable
  include Sanitizable

  TYPES = Edition.types.values

  def perform(products_with_editions)
    editions_api_response = get_editions(products_with_editions, "publish")
    parsed_woo_editions = parse(editions_api_response)
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

  def parse(editions_api_response)
    editions_api_response.map { Woo::Edition.deserialize(it) }.compact
  end

  def create(parsed_editions_api_response)
    parsed_editions_api_response.each { Woo::Edition.import(it) }
  end

  def create_edition(
    product:,
    edition_woo_id:,
    edition_types:,
    store_link: nil
  )
    Woo::Edition.import(
      woo_id: edition_woo_id,
      product_woo_id: product.woo_id,
      store_link: store_link,
      options: edition_types
    )
    edition_types = [edition_types] if edition_types.is_a? Hash

    mapped_edition_types = edition_types.map do |edition_type|
      # type_name == "size", "version" or "color"
      type_name = TYPES.find { |type|
        type.include? edition_type[:type]
      }&.first&.downcase

      if type_name == "Size"
        edition_type[:value] = Size.sanitize_size(edition_type[:value])
      end

      next if type_name.blank?

      type_instance = type_name.capitalize.constantize.find_or_create_by({
        value: edition_type[:value]
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

    edition = Edition.find_or_initialize_by(woo_id: edition_woo_id)

    edition.assign_attributes({
      product:,
      store_link:
    }.merge(*mapped_edition_types).compact)

    edition.save

    edition
  end
end
