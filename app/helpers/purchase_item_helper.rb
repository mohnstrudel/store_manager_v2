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
      options: purchase_item_form_options(purchase_item)
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
      expenses: "",
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
      expenses: purchase_item.expenses.to_s,
      shipping_cost: purchase_item.shipping_cost.to_s,
      tracking_number: purchase_item.tracking_number.to_s,
      media: purchase_item_media_form_props(purchase_item),
      redirect_to_sale_item:
    }
  end

  def purchase_item_form_options(purchase_item)
    {
      warehouses: Warehouse.order(:name).map { |w| {value: w.id, label: w.name} },
      purchases: Purchase.for_form_select.map { |p| {value: p.id, label: p.full_title} },
      sale_items: SaleItem.for_edit_linking(purchase_item).map { |si| {value: si.id, label: si.build_title_for_select} },
      shipping_companies: ShippingCompany.order(:name).map { |sc| {value: sc.id, label: sc.name} }
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
