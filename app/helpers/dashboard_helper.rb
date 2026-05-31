# frozen_string_literal: true

module DashboardHelper
  def dashboard_debts_props(debts, unpaid_purchases:, search:)
    {
      debts: debts.map { |debt| dashboard_debt_props(debt) },
      pagination: pagination_props(debts),
      search: search,
      unpaid_purchases: unpaid_purchases.map { |purchase| dashboard_unpaid_purchase_props(purchase) }
    }
  end

  def dashboard_index_props(sale_debts:, suppliers_debts:, total_suppliers_debt:, sales_hook_disabled:, last_orders_pull_path:, debts_path:)
    {
      sales_hook_disabled: sales_hook_disabled,
      last_orders_pull_path: last_orders_pull_path,
      sale_debts: sale_debts.first(5).map { |product| dashboard_sale_debt_props(product) },
      sale_debts_count: sale_debts.length,
      suppliers_debts: suppliers_debts.filter_map { |supplier_debt| dashboard_supplier_debt_props(supplier_debt) },
      total_suppliers_debt: format_money(total_suppliers_debt, "$"),
      debts_path: debts_path
    }
  end

  def dashboard_sale_debt_props(product)
    {
      id: product.id,
      path: product_path(product.slug),
      row_id: product.sale_variant_id || product.id,
      title: product.full_title,
      variant_name: product.sale_variant_id.present? ? product.variant_name : "-",
      debt: product.debt.to_i
    }
  end

  def dashboard_supplier_debt_props(supplier_debt)
    return if supplier_debt[:total_debt].zero?

    supplier = supplier_debt[:supplier]

    {
      supplier_id: supplier.id,
      supplier_title: supplier.title,
      supplier_path: supplier_path(supplier),
      total_cost: format_money(supplier_debt[:total_cost]),
      total_size: supplier_debt[:total_size].to_i,
      paid: format_money(supplier_debt[:paid]),
      total_debt: format_money(supplier_debt[:total_debt])
    }
  end

  def dashboard_debt_props(product)
    variant = product.sale_variant_id.present?

    {
      id: product.id,
      path: product_path(product.slug),
      row_id: product.sale_variant_id || product.id,
      title: product.full_title,
      variant_name: variant ? product.variant_name : "",
      sold_amount: product.sold_amount.to_i,
      purchased_amount: variant ? product.purchased_variants_amount.to_i : product.purchased_amount.to_i,
      debt: variant ? product.variants_debt.to_i : product.debt.to_i
    }
  end

  def dashboard_unpaid_purchase_props(purchase)
    {
      id: purchase.id,
      path: purchase_path(purchase),
      purchased_ago: time_ago_in_words(purchase.created_at),
      supplier_title: purchase.supplier.title,
      item_price: format_money(purchase.item_price),
      amount: purchase.amount.to_i
    }
  end
end
