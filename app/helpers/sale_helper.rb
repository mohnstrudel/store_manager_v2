# frozen_string_literal: true

module SaleHelper
  def sale_listing_props(sale)
    sale_base_props(sale).merge(
      customer_name: sale.customer.full_name,
      customer_email: sale.customer.email,
      sale_items: sale.sale_items.map { |item| sale_index_item_props(item) },
      payment: sale_payment_props(sale),
      **sale_payment_context_props(sale)
    )
  end

  def sale_payment_props(sale)
    pie = payment_pie_total(sale.expected_revenue, sale.received_revenue, sale.outstanding_revenue)

    {
      progress: [percent_of(sale.received_revenue, pie) || 0, 100].min,
      amounts_unknown: sale.payment_split_unknown?,
      paid: format_money(sale.received_revenue),
      price: format_money(pie),
      debt: format_money(sale.outstanding_revenue),
      payment_overdue: sale.payment_overdue
    }
  end

  def sale_showing_props(sale, can_view_profitability: false)
    shipping_shares = sale.shipping_shares_by_item_id
    expense_fraction = can_view_profitability ? ExpenseRate.combined_fraction : 0
    follow_up_payment = sale.follow_up_payment?

    sale_base_props(sale).merge(
      edit_path: edit_sale_path(sale),
      can_link_purchase_items: (sale.active? || sale.completed?) && sale.unlinked_sale_items?,
      link_purchase_items_path: sale_purchase_item_link_path(sale),
      pull_path: sale_pull_path(sale),
      shop_admin_url: sale_shop_link(sale),
      customer: sale_customer_props(sale.customer),
      note: sale.note,
      payment: sale_payment_props(sale),
      **sale_payment_context_props(sale),
      profitability: (can_view_profitability && !follow_up_payment) ? sale_profitability_props(sale, expense_fraction) : nil,
      warehouses: Warehouse.order(name: :asc).map { |w| purchase_warehouse_props(w) },
      warehouse_move_path: warehouse_move_path,
      sale_items: follow_up_payment ? [] : sale.sale_items.map { |item|
        sale_show_item_props(item, shipping_shares.fetch(item.id, 0), can_view_profitability:, expense_fraction:)
      }
    ).merge(follow_up_payment ? {} : sale_order_only_props(sale))
  end

  def sale_order_only_props(sale)
    {
      shipping_address: sale_address_props(sale.shipping_address),
      billing_address: sale_address_props(sale.billing_address),
      billing_differs_from_shipping: sale.billing_differs_from_shipping?,
      discount_total: format_money(sale.discount_total),
      shipping_total: format_money(sale.shipping_total)
    }
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

  def sale_payment_context_props(sale)
    plans = sale.payment_plans_for_display

    {
      partially_paid: plans.empty? && sale.partially_paid?,
      payment_plans: plans.map { |plan| sale_payment_plan_props(plan, sale) }
    }
  end

  private

  def sale_profitability_props(sale, expense_fraction)
    summary = sale.profitability_summary(expense_fraction:)
    return if summary.nil?

    {
      scope: summary[:scope],
      gross_revenue: format_money(summary[:gross_revenue]),
      item_price_total: format_money(summary[:item_price_total]),
      purchase_expenses: format_money(summary[:purchase_expenses]),
      purchase_shipping_cost: format_money(summary[:purchase_shipping_cost]),
      direct_expenses: format_money(summary[:direct_expenses]),
      business_expenses: format_money(summary[:business_expenses]),
      net_profit: format_money(summary[:net_profit]),
      collected_revenue: format_money(summary[:collected_revenue]),
      purchase_paid: format_money(summary[:purchase_paid]),
      cash_position: format_money(summary[:cash_position])
    }
  end

  def sale_payment_plan_props(plan, sale)
    remainder = plan.projected_remainder

    {
      id: plan.id,
      kind: plan.kind,
      expected_parts: plan.expected_parts,
      collected_parts: plan.collected_parts,
      sale_part_number: plan.part_number_for(sale),
      is_origin_sale: plan.origin_sale_id == sale.id,
      deposit_percent: compact_number(plan.deposit_percent),
      projected_total: format_plan_money(plan.projected_total, plan.currency),
      projected_collected: sale_payment_plan_collected_props(plan, remainder),
      origin_sale: sale_payment_plan_origin_props(plan, sale),
      payments: plan.linked_parts.map { |part| sale_payment_plan_payment_props(part, sale) }
    }
  end

  def sale_payment_plan_collected_props(plan, remainder)
    return if plan.projected_total.nil?

    format_plan_money(plan.projected_total - remainder, plan.currency)
  end

  def sale_payment_plan_origin_props(plan, sale)
    origin = plan.origin_sale
    return if origin.nil? || origin.id == sale.id

    {path: sale_path(origin), identifier: sale_reference_identifier(origin)}
  end

  def sale_payment_plan_payment_props(part, sale)
    {
      sequence: part.sequence,
      path: sale_path(part.sale),
      identifier: sale_reference_identifier(part.sale),
      is_current_sale: part.sale_id == sale.id
    }
  end

  def sale_reference_identifier(sale)
    sale.shop_identifier.presence || sale.id.to_s
  end

  def compact_number(value)
    return if value.nil?

    value.to_d.frac.zero? ? value.to_i : value.to_f
  end

  def format_plan_money(value, currency)
    format_money(value, currency.to_s)
  end

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
      shop_identifier: sale.shop_identifier,
      is_follow_up_payment: sale.follow_up_payment?
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
      address&.public_send(attr)
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

  def sale_show_item_props(item, shipping_share, can_view_profitability: false, expense_fraction: ExpenseRate.combined_fraction)
    {
      id: item.id,
      title: item.title,
      qty: item.qty,
      product_path: product_path(item.product),
      product_thumb_url: thumb_url(item.product),
      purchase_items: item.purchase_items.map { |pi| sale_show_purchase_item_props(pi) },
      payment: sale_item_payment_props(item, shipping_share),
      profitability: can_view_profitability ? sale_item_profitability_props(item, expense_fraction) : nil
    }
  end

  def sale_item_payment_props(item, shipping_share)
    received = item.received_revenue.to_d
    total = item.expected_revenue.to_d + shipping_share
    debt = [total - received, 0].max

    {
      progress: [percent_of(received, total) || 0, 100].min,
      amounts_unknown: item.payment_split_unknown?,
      paid: format_money(received),
      price: format_money(total),
      debt: format_money(debt)
    }
  end

  def sale_item_profitability_props(item, expense_fraction = ExpenseRate.combined_fraction)
    {
      expected_revenue: format_money(item.expected_revenue),
      purchase_cost: format_money(item.purchase_cost),
      expected_final_profit: format_money(item.expected_final_profit(expense_fraction))
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
    {
      id: item.id,
      product_id: item.product_id,
      variant_id: item.variant_id,
      qty: item.qty.to_s,
      price: item.price.to_s,
      _destroy: false,
      variant_availability: variant_availability_props(item.product, current_variant: item.variant)
    }
  end
end
