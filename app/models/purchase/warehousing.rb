# frozen_string_literal: true

module Purchase::Warehousing
  extend ActiveSupport::Concern

  def move_to_warehouse!(warehouse_id)
    if purchase_items.exists?
      PurchaseItem.move_to_warehouse!(
        purchase_item_ids: purchase_items.order(:id).pluck(:id),
        warehouse_id:
      )
    else
      create_items_in_warehouse!(warehouse_id)
    end
  end

  def link_with_sales
    link_purchase_items
  end

  private

  def create_items_in_warehouse!(warehouse_id)
    purchase_items_attributes = Array.new(amount) {
      {
        purchase_id: id,
        warehouse_id:,
        created_at: Time.current,
        updated_at: Time.current
      }
    }
    created_purchase_items = purchase_items.create!(purchase_items_attributes)
    link_with_sales
    created_purchase_items.size
  end
end
