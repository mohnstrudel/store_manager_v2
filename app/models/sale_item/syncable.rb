# frozen_string_literal: true

module SaleItem::Syncable
  extend ActiveSupport::Concern

  included do
    belongs_to :shopify_variant_info, -> { shopify.where(storable_type: "Variant") },
      class_name: "StoreInfo", primary_key: :store_id, foreign_key: :shopify_variant_id,
      optional: true, inverse_of: false

    scope :shopify_variant_unlinked, -> {
      where.not(shopify_variant_id: nil).where.missing(:shopify_variant_info)
    }
  end

  def shopify_variant_unlinked?
    shopify_variant_id.present? && shopify_variant_info.nil?
  end
end
