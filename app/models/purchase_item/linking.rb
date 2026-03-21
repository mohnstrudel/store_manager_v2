# frozen_string_literal: true

module PurchaseItem::Linking
  extend ActiveSupport::Concern

  included do
    scope :available_for_product_linking, ->(product_id) {
      paid_priority = Arel.sql(
        "CASE WHEN purchases.payments_count > 0 THEN 0 ELSE 1 END ASC"
      )
      where(sale_item_id: nil)
        .joins(:purchase)
        .where(purchases: {product_id:})
        .order(paid_priority, created_at: :asc)
    }
  end

  def link_with(sale_item_id)
    update!(sale_item_id:)
  end
end
