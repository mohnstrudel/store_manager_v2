# frozen_string_literal: true

class Purchase::Linker
  def self.link(arg)
    new(arg).link
  end

  def initialize(purchase)
    raise ArgumentError, "Missing purchase" if purchase.blank?

    @purchase = purchase
    @linked_ids = []
  end

  def link
    return if @purchase.purchase_items.blank?

    unlinked_purchase_items = @purchase.purchase_items.where(sale_item_id: nil).to_a

    SaleItem.linkable_for(@purchase).each do |sale_item|
      break if unlinked_purchase_items.empty?

      remaining = [sale_item.qty, @purchase.amount, unlinked_purchase_items.size].min

      unlinked_purchase_items.shift(remaining).each do |purchase_item|
        purchase_item.link_to_sale_item!(sale_item.id)
        @linked_ids << purchase_item.id
      end
    end

    @linked_ids
  end
end
