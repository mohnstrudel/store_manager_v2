class SyncWooVariationsJob < ApplicationJob
  queue_as :default

  include Gettable
  include Sanitizable

  def perform(products_with_variations)
    woo_variations = get_variations(products_with_variations, "publish")
    parsed_woo_variations = parse(woo_variations)
    create(parsed_woo_variations)
  end

  def get_variations(products_with_variations, status)
    total = products_with_variations.size
    progressbar = ProgressBar.create(
      title: self.class.name + " of #{total} products variations",
      total:
    )
    products_with_variations.map do |product_woo_id|
      progressbar.increment
      warn "Downloading variations for product: #{product_woo_id}"
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

      attributes = variation[:attributes].each_with_object({}) do |attr, attrs|
        next if attr[:option].blank?
        option = smart_titleize(sanitize(attr[:option]))
        case attr[:name]
        when *Variation.types[:version]
          attrs[:version] = option
        when *Variation.types[:size]
          attrs[:size] = option
        when *Variation.types[:color]
          attrs[:color] = option
        end
      end

      result.merge(attributes)
    rescue => e
      Rails.logger.error "SyncWooVariationsJob. Error: #{e.message}"
      nil
    end.compact_blank
  end

  def create(parsed_woo_variations)
    parsed_woo_variations.each do |variation|
      next if variation.blank?

      size = if variation[:size].present?
        Size.find_or_create_by(value: Size.parse_size(variation[:size]))
      end

      version = if variation[:version].present?
        Version.find_or_create_by(value: sanitize(variation[:version]))
      end

      color = if variation[:color].present?
        Color.find_or_create_by(value: sanitize(variation[:color]))
      end

      product = Product.find_or_create_by(woo_id: variation[:product_woo_id])

      Variation.create({
        woo_id: variation[:woo_id],
        store_link: variation[:store_link],
        size:,
        version:,
        color:,
        product:
      })
    end
  end
end
