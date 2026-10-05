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
      where("qty > purchase_items_count").where(origin_sale_item_id: nil)
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
      return none unless purchase_item.product_id && purchase_item.variant_id

      available = for_linking.linkable.where(
        product_id: purchase_item.product_id,
        variant_id: purchase_item.variant_id
      )
      currently_linked = purchase_item.sale_item_id ? for_linking.where(id: purchase_item.sale_item_id) : none

      available.or(currently_linked).order(:id)
    end

    def for_linking_table(purchase_item)
      return none unless purchase_item.product_id && purchase_item.variant_id

      exact_matches = where(
        product_id: purchase_item.product_id,
        variant_id: purchase_item.variant_id
      )
      currently_linked = purchase_item.sale_item_id ? where(id: purchase_item.sale_item_id) : none

      exact_matches
        .or(currently_linked)
        .includes(:shopify_info, :woo_info, sale: [:customer, :woo_info], purchase_items: [:warehouse, {purchase: :supplier}])
        .order(purchase_items_count: :asc, id: :asc)
    end
  end

  def resolve_sold_item
    variant.presence || product
  end
end
