# frozen_string_literal: true

module Purchase::Linking
  extend ActiveSupport::Concern

  def link_purchase_items
    return if purchase_items.blank? || amount.to_i <= 0

    eligible_purchase_items = purchase_items
      .where(sale_item_id: nil)
      .order(:id)
      .limit(amount)

    PurchaseItem.link_available_to_sale_items!(
      sale_items: SaleItem.linkable_for(self).order(:id).to_a,
      purchase_items: eligible_purchase_items
    )
  end
end
