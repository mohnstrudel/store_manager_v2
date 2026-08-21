# frozen_string_literal: true

module PurchaseItemHelper
  def purchase_item_index_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      edit_path: edit_purchase_item_path(purchase_item),
      purchase_path: purchase_path(purchase_item.purchase),
      purchase_title: purchase_item.purchase.full_title,
      product_path: purchase_product_path(purchase_item.purchase),
      product_title: purchase_product_title(purchase_item.purchase),
      variant_title: purchase_item.purchase.variant_title,
      warehouse_name: purchase_item.warehouse.name,
      warehouse_path: warehouse_path(purchase_item.warehouse),
      sale_path: purchase_item.sale ? sale_path(purchase_item.sale) : nil,
      sale_title: purchase_item.sale&.full_title,
      customer_email: purchase_item.customer&.email,
      tracking_number: safe_blank_render(purchase_item.tracking_number),
      shipping_company_name: safe_blank_render(purchase_item.shipping_company&.name),
      shipping_cost: format_money(purchase_item.shipping_cost),
      updated_at: format_date(purchase_item.updated_at)
    }
  end

  def purchase_item_edit_props(purchase_item, redirect_to_sale_item: false)
    {
      purchase_item: purchase_item_form_record(purchase_item, redirect_to_sale_item:),
      options: purchase_item_form_options(purchase_item),
      sale_items_table: purchase_item_sale_items_table_data(purchase_item)
    }
  end

  def purchase_item_new_props(purchase_item, warehouse:)
    {
      purchase_item: purchase_item_new_record(purchase_item, warehouse:),
      options: purchase_item_form_options(purchase_item),
      form_action: warehouse_items_path(warehouse),
      cancel_path: warehouse_path(warehouse)
    }
  end

  def purchase_item_show_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      edit_path: edit_purchase_item_path(purchase_item),
      destroy_path: purchase_item_path(purchase_item),
      purchase_path: purchase_path(purchase_item.purchase),
      purchase_title: purchase_item.purchase.full_title,
      sale_path: purchase_item.sale ? sale_path(purchase_item.sale) : nil,
      sale_item_path: purchase_item.sale_item ? sale_item_path(purchase_item.sale, purchase_item.sale_item) : nil,
      supplier_title: purchase_item.purchase.supplier.title,
      supplier_path: supplier_path(purchase_item.purchase.supplier),
      product_title: purchase_product_title(purchase_item.purchase),
      product_path: purchase_product_path(purchase_item.purchase),
      warehouse_name: purchase_item.warehouse.name,
      warehouse_path: warehouse_path(purchase_item.warehouse),
      expenses: format_money(safe_blank_render(purchase_item.expenses)),
      shipping_cost: format_money(safe_blank_render(purchase_item.shipping_cost)),
      tracking_number: safe_blank_render(purchase_item.tracking_number),
      shipping_company_name: safe_blank_render(purchase_item.shipping_company&.name),
      length: safe_blank_render(purchase_item.length),
      width: safe_blank_render(purchase_item.width),
      height: safe_blank_render(purchase_item.height),
      weight: safe_blank_render(purchase_item.weight),
      created_at: format_date(purchase_item.created_at),
      updated_at: format_date(purchase_item.updated_at),
      media: purchase_item.media.filter_map { |media| media_props(media) },
      warehouse_movements: purchase_item.warehouse_movements.map.with_index do |movement, index|
        {
          id: index,
          moved_in: format_datetime(movement.moved_in),
          warehouse_name: movement.warehouse&.name,
          warehouse_path: movement.warehouse ? warehouse_path(movement.warehouse) : nil
        }
      end
    }
  end

  private

  def purchase_item_new_record(purchase_item, warehouse:)
    {
      id: nil,
      path: "",
      purchase_id: nil,
      sale_item_id: nil,
      warehouse_id: warehouse.id,
      shipping_company_id: nil,
      length: "",
      width: "",
      height: "",
      weight: "",
      shipping_cost: "",
      tracking_number: "",
      media: [],
      redirect_to_sale_item: false
    }
  end

  def purchase_item_form_record(purchase_item, redirect_to_sale_item:)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      purchase_id: purchase_item.purchase_id,
      sale_item_id: purchase_item.sale_item_id,
      warehouse_id: purchase_item.warehouse_id,
      shipping_company_id: purchase_item.shipping_company_id,
      length: purchase_item.length.to_s,
      width: purchase_item.width.to_s,
      height: purchase_item.height.to_s,
      weight: purchase_item.weight.to_s,
      shipping_cost: purchase_item.shipping_cost.to_s,
      tracking_number: purchase_item.tracking_number.to_s,
      media: purchase_item_media_form_props(purchase_item),
      redirect_to_sale_item:
    }
  end

  def purchase_item_form_options(purchase_item)
    {
      warehouses: Rails.cache.fetch(["pif/warehouses", Warehouse.maximum(:updated_at)]) {
        Warehouse.order(:name).pluck(:id, :name).map { |id, name| {value: id, label: name} }
      },
      purchases: Rails.cache.fetch(["pif/purchases", Purchase.maximum(:updated_at)]) {
        purchase_options_for_select
      },
      shipping_companies: Rails.cache.fetch(["pif/shipping_companies", ShippingCompany.maximum(:updated_at)]) {
        ShippingCompany.order(:name).pluck(:id, :name).map { |id, name| {value: id, label: name} }
      }
    }
  end

  def purchase_item_sale_items_table_data(purchase_item)
    SaleItem.for_linking_table(purchase_item).flat_map do |si|
      customer = si.sale.customer
      customer_name = [customer&.first_name, customer&.last_name].compact.join(" ").presence
      identifier = si.sale.shop_identifier.presence || "##{si.sale_id}"
      sale_label = ["Sale #{identifier}", customer_name, customer&.email].compact.join(" | ")

      base = {
        sale_item_id: si.id,
        sale_label:,
        sale_path: sale_path(si.sale),
        link_path: purchase_item_sale_item_link_path(purchase_item),
        unlink_path: purchase_item_sale_item_link_path(purchase_item)
      }

      actual_linked = si.purchase_items.size
      available_count = [(si.qty || actual_linked).to_i - actual_linked, 0].max

      available_rows = available_count.times.map.with_index { |_, i|
        base.merge(
          slot_key: "#{si.id}-available-#{i}",
          warehouse: nil,
          warehouse_path: nil,
          linked_purchase_item: nil,
          is_current: false,
          is_available: true
        )
      }

      linked_rows = si.purchase_items.map { |pi|
        base.merge(
          slot_key: "#{si.id}-pi-#{pi.id}",
          warehouse: pi.warehouse&.name,
          warehouse_path: pi.warehouse ? warehouse_path(pi.warehouse) : nil,
          linked_purchase_item: {
            id: pi.id,
            path: edit_purchase_item_path(pi),
            purchase_id: pi.purchase_id,
            purchase_path: purchase_path(pi.purchase),
            supplier_title: pi.purchase.supplier.title,
            purchase_date: format_date(pi.purchase.date),
            item_price: format_money(pi.purchase.item_price)
          },
          is_current: pi.id == purchase_item.id,
          is_available: false
        )
      }

      available_rows + linked_rows
    end
  end

  def purchase_options_for_select
    Purchase
      .joins(:supplier)
      .left_outer_joins(:product)
      .order(purchase_date: :desc, created_at: :desc)
      .pluck(:id, "suppliers.title", "products.full_title",
        Arel.sql("COALESCE(purchases.purchase_date, purchases.created_at)"))
      .map { |id, supplier, product, date|
        {value: id, label: "#{supplier} | #{product} | #{date&.strftime("%Y-%m-%d")}"}
      }
  end

  def purchase_item_media_form_props(purchase_item)
    purchase_item.media.filter_map do |media|
      next unless media.image.attached?

      {
        id: media.id,
        alt: media.alt,
        position: media.position,
        preview_url: url_for(media.image.representation(:preview)),
        thumb_url: url_for(media.image.representation(:thumb)),
        image_blob_id: nil,
        _destroy: false
      }
    end
  end
end
