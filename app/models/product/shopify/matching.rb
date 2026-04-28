# frozen_string_literal: true

module Product::Shopify::Matching
  extend ActiveSupport::Concern

  class_methods do
    def find_storeless_match_for_shopify(franchise_title:, product_title:, shape_title:, brand_titles:, size_values:)
      normalized_brand_titles = Array(brand_titles).compact_blank.sort
      normalized_size_values = Array(size_values).compact_blank.sort

      storeless_for_shopify_match.find do |product|
        product.shopify_id.blank? &&
          product.shopify_info&.store_id.blank? &&
          product.franchise&.title == franchise_title &&
          product.title == product_title &&
          product.shape == shape_title &&
          product.brands.map(&:title).sort == normalized_brand_titles &&
          product.sizes.map(&:value).sort == normalized_size_values
      end
    end

    private

    def storeless_for_shopify_match
      where(shopify_id: nil)
        .includes(:franchise, :brands, :sizes, :shopify_info, :woo_info)
        .order(:id)
    end
  end
end
