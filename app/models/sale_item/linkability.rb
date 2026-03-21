# frozen_string_literal: true

module SaleItem::Linkability
  extend ActiveSupport::Concern

  included do
    scope :active, -> {
      joins(:sale).where(sales: {status: Sale.active_status_names})
    }

    scope :completed, -> {
      joins(:sale).where(sales: {status: Sale.completed_status_names})
    }

    scope :linkable, -> {
      where("qty > purchase_items_count")
    }
  end

  class_methods do
    def linkable_for(purchase)
      active
        .linkable
        .where(
          purchase.edition_id.present? ?
            {edition_id: purchase.edition_id} :
            {product_id: purchase.product_id, edition_id: nil}
        )
    end

    def linkable_with(purchase)
      linkable_for(purchase)
    end
  end

  def resolve_sold_item
    edition.presence || product
  end
end
