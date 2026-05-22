# frozen_string_literal: true

module Warehouses
  class DetailsController < ApplicationController
    def show
      @warehouse = Warehouse.for_details.find(params[:id])
      @selected_id = params[:selected].presence&.to_i
      @purchase_items = @warehouse
        .purchase_items
        .for_warehouse_details
        .order(updated_at: :desc)
        .page(params[:page])
      @total_purchase_items = @warehouse.purchase_items.size
      @purchase_items = @purchase_items.search(params[:q]) if params[:q].present?

      render inertia: "Warehouses/Show", props: {
        warehouse: warehouse_props(@warehouse),
        purchase_items: @purchase_items.map { |purchase_item| purchase_item_props(purchase_item) },
        pagination: pagination_props(@purchase_items),
        search: {q: params[:q].to_s},
        selected_id: @selected_id,
        total_purchase_items: @total_purchase_items,
        warehouses: Warehouse.order(name: :asc).map { |warehouse| {id: warehouse.id, name: warehouse.name.to_s} },
        warehouse_move_path: warehouse_move_path(warehouse_id: @warehouse.id)
      }
    end

    private

    def authorize_resourse
      authorize :warehouse
    end

    def warehouse_props(warehouse)
      {
        id: warehouse.id,
        name: warehouse.name.to_s,
        edit_path: edit_warehouse_path(warehouse),
        destroy_path: warehouse_path(warehouse),
        new_item_path: new_warehouse_item_path(warehouse),
        external_name_en: helpers.safe_blank_render(warehouse.external_name_en).to_s,
        desc_en: helpers.safe_blank_render(warehouse.desc_en).to_s,
        external_name_de: helpers.safe_blank_render(warehouse.external_name_de).to_s,
        desc_de: helpers.safe_blank_render(warehouse.desc_de).to_s,
        cbm: helpers.safe_blank_render(warehouse.cbm).to_s,
        container_tracking_number: helpers.safe_blank_render(warehouse.container_tracking_number).to_s,
        courier_tracking_url: warehouse.courier_tracking_url.to_s,
        is_default: warehouse.is_default?,
        created_at: helpers.format_date(warehouse.created_at).to_s,
        media: warehouse.media.filter_map { |media| media_props(media) },
        payment_progress: {
          progress: warehouse.average_payment_progress.to_f,
          paid: "",
          price: "",
          debt: helpers.format_money(warehouse.total_debt).to_s
        }
      }
    end

    def purchase_item_props(item)
      sale = item.sale
      {
        id: item.id,
        path: purchase_item_path(item),
        title: item.purchase.product.full_title.to_s,
        variant_title: item.purchase.variant&.title.to_s,
        sku: item.purchase.variant&.sku || item.purchase.product&.base_variant&.sku || "-",
        sale_path: sale ? sale_path(sale) : nil,
        sale_title: sale&.title.to_s,
        sale_store_type: sale_store_type(sale),
        sale_summary: sale ? helpers.sale_summary_for_warehouse(sale) : "",
        sale_note: sale&.note.to_s,
        customer_email: sale&.customer&.email.to_s,
        tracking_number: item.tracking_number.to_s,
        tracking_edit_path: edit_purchase_item_tracking_number_path(item),
        shipping_company_name: item.shipping_company&.name.to_s,
        shipping_company_edit_path: edit_purchase_item_shipping_company_path(item),
        payment_progress: {
          progress: item.purchase.progress.to_f,
          paid: helpers.format_money(item.purchase.item_paid).to_s,
          price: helpers.format_money(item.purchase.item_price).to_s,
          debt: helpers.format_money(item.purchase.item_debt).to_s
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
end
