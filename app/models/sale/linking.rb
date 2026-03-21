# frozen_string_literal: true

module Sale::Linking
  extend ActiveSupport::Concern

  def has_unlinked_sale_items?
    total_sold = sale_items.sum(:qty)
    total_purchased = sale_items.sum { |sale_item| sale_item.purchase_items.size }

    return if total_sold == total_purchased

    product_ids = sale_items.pluck(:product_id)

    PurchaseItem.available_for_product_linking(product_ids).exists?
  end

  def link_with_purchase_items
    return unless active? || completed?

    sale_items.linkable.map do |sale_item|
      already_linked_size = sale_item.purchase_items.count
      remaining_size = sale_item.qty - already_linked_size

      next if remaining_size <= 0

      linkable_purchase_items = PurchaseItem
        .available_for_product_linking(sale_item.product_id)
        .limit(remaining_size)

      linked_purchase_items_ids = linkable_purchase_items.pluck(:id)

      linkable_purchase_items.each { it.link_with(sale_item.id) }

      linked_purchase_items_ids
    end.compact.flatten
  end
end
