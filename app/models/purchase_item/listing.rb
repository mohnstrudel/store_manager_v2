# frozen_string_literal: true

module PurchaseItem::Listing
  extend ActiveSupport::Concern

  included do
    scope :ordered_by_updated_date, -> { order(updated_at: :desc) }

    scope :with_media, -> { includes(media: {image_attachment: :blob}) }

    scope :for_purchase_details, -> {
      includes(:warehouse, :sale_item, purchase: :payments, sale: [:customer, :shopify_info, :woo_info])
    }

    scope :for_warehouse_details, -> {
      includes(
        :shipping_company,
        sale: :customer,
        purchase: [
          :payments,
          :purchase_items,
          :variant,
          {product: :variants}
        ]
      )
    }

    scope :for_shipping_details, -> {
      includes(:product, :purchase, variant: [:color, :size, :version])
    }

    scope :for_notifications, -> {
      includes(
        :warehouse,
        sale: :customer,
        sale_item: [
          :product,
          variant: [:size, :version, :color]
        ]
      )
    }
  end
end
