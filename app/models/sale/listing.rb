# frozen_string_literal: true

module Sale::Listing
  extend ActiveSupport::Concern

  included do
    scope :ordered_by_shop_created_at, -> {
      order(
        Arel.sql("COALESCE(shopify_created_at, woo_created_at, created_at) DESC")
      )
    }

    scope :for_listing, -> {
      includes(
        :customer,
        :shopify_info,
        :woo_info,
        sale_items: [
          {product: {media: {image_attachment: :blob}}},
          {purchase_items: [:warehouse, purchase: :supplier]},
          {edition: [:version, :color, :size]}
        ]
      )
    }

    scope :for_details, -> {
      includes(
        :shopify_info,
        :woo_info,
        sale_items: [
          {product: {media: {image_attachment: :blob}}},
          {purchase_items: [:warehouse, purchase: :supplier]}
        ]
      )
    }
  end
end
