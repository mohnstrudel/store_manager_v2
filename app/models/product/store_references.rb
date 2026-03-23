# frozen_string_literal: true

module Product::StoreReferences
  extend ActiveSupport::Concern

  included do
    scope :with_store_references, -> {
      includes(:shopify_info, :woo_info).order(:full_title)
    }
  end

  def build_full_title_with_shop_id
    shop_ids = [shopify_info&.id_short&.presence, woo_info&.store_id&.presence].compact.join(" | ")
    "#{full_title} | #{shop_ids.presence || "N/A"}"
  end

  def build_shopify_url
    return "https://handsomecake.com/" unless shopify_info&.slug

    "https://handsomecake.com/products/#{shopify_info.slug}"
  end
end
