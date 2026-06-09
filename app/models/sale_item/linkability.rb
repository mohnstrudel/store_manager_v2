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
          purchase.variant_id.present? ?
            {variant_id: purchase.variant_id} :
            {product_id: purchase.product_id, variant_id: nil}
        )
    end

    def for_edit_linking(purchase_item)
      purchase_product_id = purchase_item.purchase&.product_id
      return none unless purchase_product_id

      available = for_linking.linkable.where(product_id: purchase_product_id)
      currently_linked = purchase_item.sale_item_id ? for_linking.where(id: purchase_item.sale_item_id) : none

      available.or(currently_linked).order(:id)
    end

    def for_linking_table(purchase_item)
      purchase_product_id = purchase_item.purchase&.product_id
      return none unless purchase_product_id

      where(product_id: purchase_product_id)
        .includes(:shopify_info, :woo_info, sale: [:customer, :woo_info], purchase_items: [:warehouse, {purchase: :supplier}])
        .order(purchase_items_count: :asc, id: :asc)
    end
  end

  def resolve_sold_item
    variant.presence || product
  end
end
