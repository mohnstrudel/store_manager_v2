class SyncWooVariationsJob < ApplicationJob
  queue_as :default

  include Gettable

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
      api_get(
        "https://store.handsomecake.com/wp-json/wc/v3/products/#{product_woo_id}/variations",
        status
      )
    end.flatten
  end

  def parse(woo_variations)
    woo_variations.map do |variation|
      result = {
        woo_id: variation[:id],
        product_woo_id: variation[:parent_id],
        store_link: variation[:permalink]
      }
      attributes = variation[:attributes].map do |attr|
        attrs = {}
        case attr[:name]
        when *Variation.types[:version]
          attrs[:version] = attr[:option]
        when *Variation.types[:size]
          attrs[:size] = attr[:option]
        when *Variation.types[:color]
          attrs[:color] = attr[:option]
        end
        attrs
      end
      result.merge(*attributes.compact.reject(&:empty?))
    end
  end

  def create(parsed_woo_variations)
    parsed_woo_variations.each do |variation|
      size = if variation[:size].present?
        Size.find_or_create_by(value: sanitize(variation[:size]))
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

  private

  def sanitize(string)
    string.tr(" ", " ").gsub(/—|–/, "-").gsub("&amp;", "&").split("|").map { |s| s.strip }.join(" | ")
  end
end
