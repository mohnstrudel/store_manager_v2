# frozen_string_literal: true

class PurchaseItems::EditResource < PurchaseItems::FormPageResource
  typelize <<~TS.squish
    Array<{
      slot_key: string;
      sale_item_id: number;
      sale_label: string;
      sale_path: string;
      warehouse: string | null;
      warehouse_path: string | null;
      linked_purchase_item: {
        id: number;
        path: string;
        purchase_id: number;
        purchase_path: string;
        supplier_title: string;
        purchase_date: string;
        item_price: string | null;
      } | null;
      is_current: boolean;
      is_available: boolean;
      link_path: string;
      unlink_path: string;
    }>
  TS
  attribute :sale_items_table do |page|
    purchase_item = page.fetch(:purchase_item)
    SaleItem.for_linking_table(purchase_item).flat_map { |sale_item| sale_item_slots(sale_item, purchase_item) }
  end

  def sale_item_slots(sale_item, purchase_item)
    base = sale_item_slot_base(sale_item, purchase_item)
    linked_count = sale_item.purchase_items.size
    available_count = [(sale_item.qty || linked_count).to_i - linked_count, 0].max

    available_slots = Array.new(available_count) do |index|
      base.merge(
        slot_key: "#{sale_item.id}-available-#{index}",
        warehouse: nil,
        warehouse_path: nil,
        linked_purchase_item: nil,
        is_current: false,
        is_available: true
      )
    end
    linked_slots = sale_item.purchase_items.map do |linked|
      base.merge(
        slot_key: "#{sale_item.id}-pi-#{linked.id}",
        warehouse: linked.warehouse&.name,
        warehouse_path: linked.warehouse ? warehouse_path(linked.warehouse) : nil,
        linked_purchase_item: linked_purchase_item(linked),
        is_current: linked.id == purchase_item.id,
        is_available: false
      )
    end

    available_slots + linked_slots
  end

  def sale_item_slot_base(sale_item, purchase_item)
    {
      sale_item_id: sale_item.id,
      sale_label: sale_label(sale_item.sale),
      sale_path: sale_path(sale_item.sale),
      link_path: purchase_item_sale_item_link_path(purchase_item),
      unlink_path: purchase_item_sale_item_link_path(purchase_item)
    }
  end

  def sale_label(sale)
    customer = sale.customer
    customer_name = [customer&.first_name, customer&.last_name].compact.join(" ").presence
    identifier = sale.shop_identifier.presence || "##{sale.id}"

    ["Sale #{identifier}", customer_name, customer&.email].compact.join(" | ")
  end

  def linked_purchase_item(purchase_item)
    {
      id: purchase_item.id,
      path: edit_purchase_item_path(purchase_item),
      purchase_id: purchase_item.purchase_id,
      purchase_path: purchase_path(purchase_item.purchase),
      supplier_title: purchase_item.purchase.supplier.title,
      purchase_date: format_date(purchase_item.purchase.date),
      item_price: format_money(purchase_item.purchase.item_price)
    }
  end
end
