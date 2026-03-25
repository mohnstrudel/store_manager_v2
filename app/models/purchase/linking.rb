# frozen_string_literal: true

module Purchase::Linking
  extend ActiveSupport::Concern

  def link_purchase_items
    return if purchase_items.blank?

    linked_purchase_item_ids = []
    unlinked_purchase_items = purchase_items.where(sale_item_id: nil).to_a

    SaleItem.linkable_for(self).each do |sale_item|
      break if unlinked_purchase_items.empty?

      remaining = [sale_item.qty, amount, unlinked_purchase_items.size].min

      unlinked_purchase_items.shift(remaining).each do |purchase_item|
        purchase_item.link_to_sale_item!(sale_item.id)
        linked_purchase_item_ids << purchase_item.id
      end
    end

    linked_purchase_item_ids
  end
end
