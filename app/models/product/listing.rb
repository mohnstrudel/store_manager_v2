# frozen_string_literal: true

module Product::Listing
  extend ActiveSupport::Concern

  included do
    scope :listed, -> {
      includes(
        :shopify_info,
        :woo_info,
        editions: [:version, :color, :size],
        media: {image_attachment: :blob}
      ).order(created_at: :desc)
    }

    scope :for_details, -> {
      includes(
        media: {image_attachment: :blob},
        purchases: [:product, :supplier, edition: [:version, :color, :size]],
        purchase_items: [:warehouse, :purchase],
        editions: [
          :version,
          :color,
          :size,
          :shopify_info,
          :woo_info,
          {sale_items: :sale},
          {purchases: :supplier}
        ],
        store_infos: [:tags]
      )
    }

    scope :for_media_sync, -> {
      includes(media: [:image_attachment, :image_blob, :shopify_info])
    }
  end
end
