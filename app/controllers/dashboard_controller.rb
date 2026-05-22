# frozen_string_literal: true

class DashboardController < ApplicationController
  include DashboardDebtReporting

  def index
    suppliers_debts = Supplier
      .includes_dashboard_associations
      .map { |supplier|
        {
          supplier:,
          total_size: supplier.purchases.size,
          total_cost: supplier.purchases.sum(&:cost_total),
          paid: supplier.purchases.sum(&:paid),
          total_debt: supplier.purchases.reduce(0) do |memo, purchase|
            memo + purchase.debt
          end
        }
      }
      .sort_by { |a| -a[:total_debt] }
    total_suppliers_debt = suppliers_debts.pluck(:total_debt).sum

    render inertia: "Dashboard/Index", props: {
      sales_hook_disabled: Config.sales_hook_disabled?,
      last_orders_pull_path: last_orders_pull_path,
      sale_debts: sale_debts.first(5).map { |product| sale_debt_props(product) },
      sale_debts_count: sale_debts.length,
      suppliers_debts: suppliers_debts.filter_map { |supplier_debt| supplier_debt_props(supplier_debt) },
      total_suppliers_debt: helpers.format_money(total_suppliers_debt, "$").to_s,
      debts_path: debts_path
    }
  end

  def noop
    render inertia: "Dashboard/Noop"
  end

  private

  def sale_debt_props(product)
    {
      id: product.id,
      path: product_path(product.slug),
      row_id: product.sale_variant_id || product.id,
      title: product.full_title.to_s,
      variant_name: product.sale_variant_id.present? ? product.variant_name.to_s : "-",
      debt: product.debt.to_i
    }
  end

  def supplier_debt_props(supplier_debt)
    return if supplier_debt[:total_debt].zero?

    supplier = supplier_debt[:supplier]

    {
      supplier_id: supplier.id,
      supplier_title: supplier.title.to_s,
      supplier_path: supplier_path(supplier),
      total_cost: helpers.format_money(supplier_debt[:total_cost]).to_s,
      total_size: supplier_debt[:total_size].to_i,
      paid: helpers.format_money(supplier_debt[:paid]).to_s,
      total_debt: helpers.format_money(supplier_debt[:total_debt]).to_s
    }
  end
end
