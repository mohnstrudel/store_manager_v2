# frozen_string_literal: true

module StoreInfo::References
  extend ActiveSupport::Concern

  def product_url(handle = nil)
    handle ||= slug
    case store_name
    when "shopify"
      "https://handsomecake.com/products/#{handle}"
    when "woo"
      return handle if handle.to_s.start_with?("http://", "https://")

      "https://store.handsomecake.com/product/#{handle}"
    end
  end

  # Store ID without GID prefix
  def id_short
    return if store_id.blank?

    shopify_api_category_name = external_name_for(storable_type)
    store_id.gsub("gid://shopify/#{shopify_api_category_name}/", "")
  end

  private

  def external_name_for(our_name)
    case our_name
    when "Sale"
      "Order"
    when "Edition"
      "ProductVariant"
    else
      our_name
    end
  end
end
