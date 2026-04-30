# frozen_string_literal: true

module Purchase::Listing
  extend ActiveSupport::Concern

  included do
    scope :for_listing, -> {
      includes(
        :supplier,
        :payments,
        {product: {media: {image_attachment: :blob}}},
        purchase_items: [:warehouse],
        variant: [:color, :size, :version]
      )
    }

    scope :for_form_select, -> {
      includes(:product, :supplier).order(purchase_date: :desc, created_at: :desc)
    }

    scope :for_supplier_details, -> {
      includes(:product, :payments, variant: [:color, :size, :version])
    }

    scope :for_details, -> {
      includes(
        :supplier,
        :payments,
        {product: {media: {image_attachment: :blob}}},
        variant: [:color, :size, :version]
      )
    }
  end
end
