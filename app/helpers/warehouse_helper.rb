# frozen_string_literal: true

module WarehouseHelper
  def warehouse_listing_props(warehouse, warehouses_count)
    {
      id: warehouse.id,
      path: warehouse_path(warehouse),
      edit_path: edit_warehouse_path(warehouse),
      position_path: warehouse_position_path(warehouse),
      position: warehouse.position,
      positions: (1..warehouses_count).to_a,
      name: warehouse.name,
      is_default: warehouse.is_default?,
      external_name_en: warehouse.external_name_en.presence || "N/A",
      cbm: warehouse.cbm.to_s,
      purchase_items_count: warehouse.purchase_items.size,
      has_purchase_items: warehouse.purchase_items.any?,
      payment_progress: {
        progress: warehouse.average_payment_progress.to_f,
        paid: "",
        price: "",
        debt: format_money(warehouse.total_debt)
      }
    }
  end

  def warehouse_show_props(warehouse, purchase_items:, search:, selected_id:, total_purchase_items:)
    {
      warehouse: warehouse_show_record_props(warehouse),
      purchase_items: purchase_items.map { |purchase_item| warehouse_details_purchase_item_props(purchase_item) },
      pagination: pagination_props(purchase_items),
      search: search,
      selected_id: selected_id,
      total_purchase_items: total_purchase_items,
      warehouses: Warehouse.order(name: :asc).map { |w| {id: w.id, name: w.name} },
      shipping_companies: ShippingCompany.ordered.map { |shipping_company|
        {id: shipping_company.id, name: shipping_company.name}
      },
      warehouse_move_path: warehouse_move_path(warehouse_id: warehouse.id)
    }
  end

  def warehouse_new_props(warehouse)
    warehouse_form_props(warehouse, positions_count: Warehouse.count + 1)
  end

  def warehouse_edit_props(warehouse)
    warehouse_form_props(warehouse, positions_count: Warehouse.count)
  end

  def warehouse_show_record_props(warehouse)
    {
      id: warehouse.id,
      name: warehouse.name,
      edit_path: edit_warehouse_path(warehouse),
      destroy_path: warehouse_path(warehouse),
      new_item_path: new_warehouse_item_path(warehouse),
      external_name_en: safe_blank_render(warehouse.external_name_en),
      desc_en: safe_blank_render(warehouse.desc_en),
      external_name_de: safe_blank_render(warehouse.external_name_de),
      desc_de: safe_blank_render(warehouse.desc_de),
      cbm: safe_blank_render(warehouse.cbm),
      container_tracking_number: safe_blank_render(warehouse.container_tracking_number),
      courier_tracking_url: warehouse.courier_tracking_url,
      is_default: warehouse.is_default?,
      created_at: format_date(warehouse.created_at),
      media: warehouse.media.filter_map { |media| media_props(media) },
      payment_progress: {
        progress: warehouse.average_payment_progress.to_f,
        paid: "",
        price: "",
        debt: format_money(warehouse.total_debt)
      }
    }
  end

  private

  def warehouse_form_props(warehouse, positions_count:)
    {
      warehouse: {
        id: warehouse.id,
        path: warehouse.persisted? ? warehouse_path(warehouse) : "",
        name: warehouse.name,
        external_name_en: warehouse.external_name_en,
        external_name_de: warehouse.external_name_de,
        desc_en: warehouse.desc_en,
        desc_de: warehouse.desc_de,
        cbm: warehouse.cbm.to_s,
        container_tracking_number: warehouse.container_tracking_number,
        courier_tracking_url: warehouse.courier_tracking_url,
        is_default: warehouse.is_default?,
        position: warehouse.position,
        media: warehouse_media_props(warehouse),
        transition_ids: warehouse.from_transitions.map(&:to_warehouse_id)
      },
      options: {
        positions: (1..positions_count).to_a,
        transition_destinations: Warehouse.where.not(id: warehouse.id).order(:name).map { |w|
          {id: w.id, name: w.name}
        }
      }
    }
  end

  def warehouse_media_props(warehouse)
    warehouse.media.filter_map do |media|
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

  def warehouse_details_purchase_item_props(item)
    sale = item.sale

    {
      id: item.id,
      path: purchase_item_path(item),
      title: item.purchase.product.full_title,
      variant_title: item.purchase.variant&.title,
      sku: item.purchase.variant&.sku || item.purchase.product&.base_variant&.sku || "-",
      sale_path: sale ? sale_path(sale) : nil,
      sale_title: sale&.title,
      sale_store_type: sale_store_type(sale),
      sale_summary: sale ? sale_summary_for_warehouse(sale) : "",
      sale_note: sale&.note,
      customer_email: sale&.customer&.email,
      tracking_number: item.tracking_number,
      tracking_update_path: purchase_item_tracking_number_path(item),
      shipping_company_name: item.shipping_company&.name,
      shipping_company_id: item.shipping_company_id,
      shipping_company_update_path: purchase_item_shipping_company_path(item),
      payment_progress: {
        progress: item.purchase.progress.to_f,
        paid: format_money(item.purchase.item_paid),
        price: format_money(item.purchase.item_price),
        debt: format_money(item.purchase.item_debt)
      }
    }
  end

  def sale_store_type(sale)
    return nil unless sale
    return "shopify" if sale.shopify_name.present? || sale.shopify_id.present?
    return "woo" if sale.woo_store_id.present?

    nil
  end
end
