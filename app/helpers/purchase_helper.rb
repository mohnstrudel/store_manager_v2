# frozen_string_literal: true

module PurchaseHelper
  def purchase_form_props(purchase, products:, suppliers:, warehouses:)
    {
      purchase: purchase_form_record_props(purchase),
      options: purchase_form_options_props(products:, suppliers:, warehouses:)
    }
  end

  def purchase_show_props(purchase, purchase_items:, payments:, new_payment:)
    {
      purchase: purchase_record_props(purchase),
      purchase_items: purchase_items.map { |purchase_item| purchase_item_props(purchase_item) },
      payments: payments.map { |payment| payment_props(payment, purchase:) },
      new_payment: unsaved_payment_props(new_payment, purchase:),
      warehouses: Warehouse.order(name: :asc).map { |warehouse| purchase_warehouse_props(warehouse) },
      warehouse_move_path: warehouse_move_path,
      shipping_companies: ShippingCompany.ordered.map { |sc| { id: sc.id, name: sc.name } }
    }
  end

  def purchase_index_props(purchase)
    {
      id: purchase.id,
      path: purchase_path(purchase),
      edit_path: edit_purchase_path(purchase),
      product_title: purchase.product.full_title,
      product_thumb_url: thumb_url(purchase.product),
      variant_title: purchase.variant&.title,
      order_reference: purchase.order_reference,
      supplier_title: purchase.supplier.title,
      amount: purchase.amount.to_i,
      purchase_items_count: purchase.purchase_items.size,
      warehouse_counts: purchase.purchase_items.group_by(&:warehouse).map do |warehouse, purchase_items|
        {
          warehouse_name: warehouse.name,
          count: purchase_items.count
        }
      end,
      payment_progress: purchase_payment_progress_props(purchase)
    }
  end

  def purchase_record_props(purchase)
    {
      id: purchase.id,
      path: purchase_path(purchase),
      edit_path: edit_purchase_path(purchase),
      destroy_path: purchase_path(purchase),
      product_path: product_path(purchase.product),
      product_title: purchase.product.full_title,
      product_image_url: purchase.product.image.presence,
      product_thumb_url: thumb_url(purchase.product),
      variant_title: purchase.variant&.title,
      amount: purchase.amount.to_i,
      item_price: format_money(purchase.item_price),
      cost_total: format_money(purchase.cost_total),
      shipping_total: format_money(purchase.shipping_total),
      paid: format_money(purchase.paid),
      debt: format_money(purchase.debt),
      supplier_title: purchase.supplier.title,
      supplier_path: supplier_path(purchase.supplier),
      order_reference: purchase.order_reference,
      date: format_date(purchase.date),
      payment_progress: purchase_payment_progress_props(purchase)
    }
  end

  def purchase_item_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      edit_path: edit_purchase_item_path(purchase_item),
      unlink_path: purchase_item_sale_item_link_path(purchase_item),
      warehouse_name: purchase_item.warehouse.name,
      warehouse_path: warehouse_path(purchase_item.warehouse, selected: purchase_item.id, anchor: purchase_item.id),
      warehouse_movements: purchase_item.warehouse_movements.sort_by(&:moved_in).reverse.drop(1).map { |m|
        {moved_in: format_datetime(m.moved_in), warehouse_name: m.warehouse&.name}
      },
      sale_title: purchase_item.sale&.select_title,
      sale_path: purchase_item.sale ? sale_path(purchase_item.sale) : nil,
      sale_address: purchase_item.sale ? sale_address_for_clipboard(purchase_item.sale) : "",
      customer_email: purchase_item.sale&.customer&.email,
      tracking_number: purchase_item.tracking_number.to_s,
      shipping_company_id: purchase_item.shipping_company_id,
      shipping_company_name: purchase_item.shipping_company&.name.to_s,
      shipping_cost: purchase_item.shipping_cost.to_i.to_s
    }
  end

  def payment_props(payment, purchase:)
    {
      id: payment.id,
      update_path: purchase_payment_path(purchase, payment),
      destroy_path: purchase_payment_path(purchase, payment, return_to: purchase_path(purchase)),
      payment_date: payment.payment_date&.to_date&.iso8601,
      value: payment.value.to_s,
      errors: payment.errors.full_messages
    }
  end

  def unsaved_payment_props(payment, purchase:)
    {
      create_path: purchase_payments_path(purchase),
      payment_date: (payment.payment_date&.to_date || Time.zone.today).iso8601,
      value: payment.value.to_s,
      errors: payment.errors.full_messages
    }
  end

  def purchase_payment_progress_props(purchase)
    {
      progress: purchase.progress.to_f,
      paid: format_money(purchase.item_paid),
      price: format_money(purchase.item_price),
      debt: format_money(purchase.item_debt)
    }
  end

  def purchase_warehouse_props(warehouse)
    {
      id: warehouse.id,
      name: warehouse.name
    }
  end

  def purchase_form_record_props(purchase)
    {
      id: purchase.id,
      path: purchase.persisted? ? purchase_path(purchase) : "",
      product_id: purchase.product_id,
      variant_id: purchase.variant_id,
      supplier_id: purchase.supplier_id,
      order_reference: purchase.order_reference.to_s,
      item_price: purchase.item_price.to_s,
      amount: purchase.amount.to_s,
      warehouse_id: purchase.warehouse_id,
      payment_value: purchase.payment_value.to_s,
      variant_options: purchase_variant_options(purchase.product)
    }
  end

  def purchase_form_options_props(products:, suppliers:, warehouses:)
    {
      products: select_option_props(products) { |product| product.build_full_title_with_shop_id },
      suppliers: select_option_props(suppliers) { |supplier| supplier.title },
      warehouses: select_option_props(warehouses) { |warehouse| warehouse.name },
      product_variants_path: product_variants_path
    }
  end

  def purchase_variant_options(product)
    return [] unless product

    select_option_props(product.fetch_variants_with_title) { |variant| variant.title }
  end

  private

  def select_option_props(collection)
    collection.map do |record|
      {
        value: record.id,
        label: yield(record)
      }
    end
  end
end
