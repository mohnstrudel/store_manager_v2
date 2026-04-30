# frozen_string_literal: true

module SaleItem::Listing
  extend ActiveSupport::Concern

  included do
    scope :for_details, -> { includes(purchase_items: :warehouse) }

    scope :for_linking, -> {
      includes(
        :product,
        sale: [:customer],
        variant: [:color, :size, :version]
      )
    }

    scope :for_history, -> {
      includes(
        :product,
        sale: [:customer, :shopify_info, :woo_info],
        variant: [:version, :color, :size]
      )
    }

    scope :for_tracking_status, -> {
      includes(:product, variant: [:version, :color, :size], purchase_items: :warehouse)
    }
  end
end
