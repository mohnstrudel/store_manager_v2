# frozen_string_literal: true

module CustomerHelper
  def customer_form_props(customer)
    {
      customer: customer_props(customer)
    }
  end

  def customer_props(customer)
    {
      id: customer.id,
      first_name: customer.first_name,
      last_name: customer.last_name,
      full_name: customer.full_name,
      email: customer.email,
      phone: customer.phone,
      woo_store_id: customer.woo_store_id,
      created_at: formatted_timestamp(customer.created_at),
      updated_at: formatted_timestamp(customer.updated_at),
      path: customer.persisted? ? customer_path(customer) : ""
    }
  end

  def customer_detail_props(customer)
    customer_props(customer).merge(
      shopify_id: customer.shopify_info&.store_id,
      shopify_id_short: customer.shopify_info&.id_short
    )
  end

  def customer_sale_props(sale)
    store_type = if sale.shopify_info&.store_id.present? || sale.shopify_name.present? || sale.shopify_id.present?
      "shopify"
    elsif sale.woo_info&.store_id.present?
      "woo"
    end

    store_id = if sale.shopify_info&.store_id.present?
      sale.shopify_info.id_short
    elsif sale.woo_info&.store_id.present?
      sale.woo_info.store_id
    else
      sale.shopify_name.presence || sale.woo_store_id
    end

    {
      id: sale.id,
      path: sale_path(sale),
      store_id: store_id,
      sale_identifier: sale.shop_identifier.presence || sale.id.to_s,
      sold_product_name: customer_sale_product_name(sale),
      product_thumb_url: customer_sale_product_thumb_url(sale),
      store_type: store_type,
      status: sale.status,
      active: sale.active?,
      total: format_money(sale.total),
      country: sale.shipping_address&.country,
      city: sale.shipping_address&.city,
      note: sale.note,
      created_at: format_date(sale.shop_created_at.presence || sale.created_at),
      updated_at: format_date(sale.shop_updated_at.presence || sale.updated_at)
    }
  end

  private

  def customer_sale_product_name(sale)
    titles = sale.sale_items.map(&:title).compact_blank
    return "" if titles.empty?
    return titles.first if titles.one?

    "#{titles.first} + #{titles.size - 1} more"
  end

  def customer_sale_product_thumb_url(sale)
    first_item = sale.sale_items.first
    return unless first_item&.product

    thumb_url(first_item.product)
  end
end
