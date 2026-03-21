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

    def for_edit_linking(purchase_item)
      statuses = Sale.active_status_names + Sale.completed_status_names
      purchase_product_id = purchase_item.purchase&.product_id

      for_linking
        .joins(:sale)
        .where(sales: {status: statuses})
        .in_order_of(:product_id, [purchase_product_id], filter: false)
        .order(:id)
    end
  end

  def resolve_sold_item
    edition.presence || product
  end
end
