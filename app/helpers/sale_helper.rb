# frozen_string_literal: true

module SaleHelper
  def sale_listing_props(sale)
    sale_base_props(sale).merge(
      customer_name: sale.customer.full_name,
      customer_email: sale.customer.email,
      sale_items: sale.sale_items.map { |item| sale_index_item_props(item) }
    )
  end

  def sale_showing_props(sale)
    sale_base_props(sale).merge(
      edit_path: edit_sale_path(sale),
      can_link_purchase_items: (sale.active? || sale.completed?) && sale.unlinked_sale_items?,
      link_purchase_items_path: sale_purchase_item_link_path(sale),
      pull_path: sale_pull_path(sale),
      shop_admin_url: sale_shop_link(sale),
      customer: sale_customer_props(sale.customer),
      shipping_address: sale_address_props(sale.shipping_address),
      billing_address: sale_address_props(sale.billing_address),
      billing_differs_from_shipping: sale.billing_differs_from_shipping?,
      note: sale.note,
      discount_total: format_money(sale.discount_total),
      shipping_total: format_money(sale.shipping_total),
      sale_items: sale.sale_items.map { |item| sale_show_item_props(item) }
    )
  end

  def sale_form_props(sale)
    {
      sale: {
        id: sale.id,
        path: sale.persisted? ? sale_path(sale) : "",
        status: sale.status,
      customer_id: sale.customer_id,
      note: sale.note,
      total: sale.total.to_s,
      discount_total: sale.discount_total.to_s,
      shipping_total: sale.shipping_total.to_s,
        shipping_address: sale_address_form_props(sale.shipping_address),
        billing_address: sale_address_form_props(sale.billing_address),
        sale_items: sale.sale_items.map { |item| sale_form_item_props(item) }
      },
      options: {
        customers: Customer.order(:email).map { |c| {value: c.id, label: c.name_and_email} },
        products: Product.with_store_references.map { |p| {value: p.id, label: p.build_full_title_with_shop_id} },
        status_names: Sale.status_names
      }
    }
  end

  def sale_summary_for_warehouse(sale)
    address = sale.shipping_address

    [
      sale.customer.full_name,
      address&.address_1,
      address&.address_2,
      address&.postcode,
      address&.city,
      address&.country,
      address&.phone.presence || sale.customer.phone
    ].compact_blank.join(", ")
  end

  def sale_address_for_clipboard(sale)
    address = sale.shipping_address

    [
      sale.customer.full_name,
      address&.address_2,
      address&.address_1,
      [address&.postcode, address&.city].compact_blank.join(" ").presence,
      address&.country,
      address&.phone.presence || sale.customer.phone
    ].compact_blank.join("\n")
  end

  def sale_item_props(sale_item)
    {
      id: sale_item.id,
      title: format_show_page_title(sale_item),
      qty: sale_item.qty.to_i,
      price: format_money(sale_item.price),
      product_path: product_path(sale_item.product),
      sale_path: sale_path(sale_item.sale)
    }
  end

  def sale_item_purchase_item_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      edit_path: edit_purchase_item_path(purchase_item, redirect_to_sale_item: true),
      unlink_path: purchase_item_sale_item_link_path(purchase_item),
      warehouse_name: purchase_item.warehouse.name,
      size: format_item_size(purchase_item),
      weight: purchase_item.weight.to_s,
      expenses: format_money(purchase_item.expenses),
      shipping_cost: format_money(purchase_item.shipping_cost)
    }
  end

  private

  def sale_base_props(sale)
    {
      id: sale.id,
      path: sale_path(sale),
      status: sale.status,
      active: sale.active?,
      completed: sale.completed?,
      total: format_money(sale.total),
      created_at: format_date(sale.shop_created_at.presence || sale.created_at),
      updated_at: format_date(sale.shop_updated_at.presence || sale.updated_at),
      shopify_name: sale.shopify_name,
      shopify_id: sale.shopify_id,
      shopify_id_short: sale.shopify_info&.id_short,
      woo_store_id: sale.woo_store_id,
      shop_identifier: sale.shop_identifier
    }
  end

  def sale_customer_props(customer)
    {
      id: customer.id,
      path: customer_path(customer),
      first_name: customer.first_name,
      last_name: customer.last_name,
      full_name: customer.full_name,
      email: customer.email,
      shopify_id_short: customer.shopify_info&.id_short,
      shop_admin_url: customer_shop_link(customer)
    }
  end

  def sale_address_props(address)
    return nil unless address

    {
      address_1: address.address_1,
      address_2: address.address_2,
      city: address.city,
      company: address.company,
      country: address.country,
      email: address.email,
      first_name: address.first_name,
      last_name: address.last_name,
      phone: address.phone,
      postcode: address.postcode,
      state: address.state
    }
  end

  def sale_address_form_props(address)
    Sale::Addresses::ADDRESS_ATTRIBUTES.index_with { |attr|
      address ? address.public_send(attr) : nil
    }
  end

  def sale_index_item_props(item)
    {
      id: item.id,
      title: item.title,
      qty: item.qty,
      purchased_count: item.purchase_items.size,
      product_thumb_url: thumb_url(item.product),
      purchase_items: item.purchase_items.map { |pi|
        {
          id: pi.id,
          path: purchase_item_path(pi),
          warehouse_name: pi.warehouse.name,
          expenses: format_money(pi.expenses)
        }
      }
    }
  end

  def sale_show_item_props(item)
    {
      id: item.id,
      title: item.title,
      price: format_money(item.price),
      qty: item.qty,
      product_path: product_path(item.product),
      product_thumb_url: thumb_url(item.product),
      purchase_items: item.purchase_items.map { |pi| sale_show_purchase_item_props(pi) }
    }
  end

  def sale_show_purchase_item_props(pi)
    {
      id: pi.id,
      path: purchase_path(pi.purchase),
      supplier_title: pi.purchase.supplier.title,
      purchase_date: format_date(pi.purchase.date),
      item_price: format_money(pi.purchase.item_price),
      unlink_path: purchase_item_sale_item_link_path(pi),
      current_warehouse_name: pi.warehouse.name,
      current_warehouse_path: warehouse_path(pi.warehouse, selected: pi.id, anchor: pi.id),
      warehouse_movements: pi.warehouse_movements.sort_by(&:moved_in).reverse.map { |m|
        {moved_in: format_datetime(m.moved_in), warehouse_name: m.warehouse&.name}
      }
    }
  end

  def sale_form_item_props(item)
    {id: item.id, product_id: item.product_id, qty: item.qty.to_s, price: item.price.to_s, _destroy: false}
  end
end
