# frozen_string_literal: true

module Purchase::Warehousing
  extend ActiveSupport::Concern

  def add_items_to_warehouse(warehouse_id)
    purchase_items_attributes = Array.new(amount) {
      {
        purchase_id: id,
        warehouse_id:,
        created_at: Time.current,
        updated_at: Time.current
      }
    }
    purchase_items.create!(purchase_items_attributes)
  end

  def link_with_sales
    linked_purchase_item_ids = Purchase::Linker.link(self)
    PurchaseItem::Notifier.handle_product_purchase(
      purchase_item_ids: linked_purchase_item_ids
    )
  end
end
