# frozen_string_literal: true

module Warehouse::Listing
  extend ActiveSupport::Concern

  included do
    scope :for_listing, -> {
      includes(:purchase_items, purchases: [:payments, :purchase_items])
    }

    scope :for_details, -> {
      includes(purchases: [:payments, :purchase_items], media: {image_attachment: :blob})
    }
  end
end
