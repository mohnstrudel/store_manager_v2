# frozen_string_literal: true

module Sale::Linking
  extend ActiveSupport::Concern

  def link_purchase_items!
    link_with_purchase_items
  end

  def unlinked_sale_items?
    total_sold = sale_items.non_installment.sum(:qty)
    total_purchased = sale_items.sum { |sale_item| sale_item.purchase_items.size }

    return if total_sold == total_purchased

    identities = sale_items.non_installment.pluck(:product_id, :variant_id)

    identities.any? do |product_id, variant_id|
      PurchaseItem
        .available_for_product_linking(product_id)
        .where(variant_id:)
        .exists?
    end
  end

  def link_with_purchase_items
    return unless active? || completed?

    PurchaseItem.link_available_to_sale_items!(
      sale_items: sale_items.linkable.order(:id).to_a
    )
  end
end
