# frozen_string_literal: true

class DashboardController < ApplicationController
  include DashboardDebtReporting

  def index
    suppliers_debts = Supplier
      .includes_dashboard_associations
      .map { |supplier|
        {
          supplier: supplier,
          total_size: supplier.purchases.size,
          total_cost: supplier.purchases.sum(&:cost_total),
          paid: supplier.purchases.sum(&:paid),
          total_debt: supplier.purchases.reduce(0) do |memo, purchase|
            memo + purchase.debt
          end
        }
      }
      .sort_by { |supplier_debt| -supplier_debt[:total_debt] }
    total_suppliers_debt = suppliers_debts.pluck(:total_debt).sum

    render inertia: "Dashboard/Index", props: helpers.dashboard_index_props(
      sale_debts: sale_debts,
      suppliers_debts: suppliers_debts,
      total_suppliers_debt: total_suppliers_debt,
      sales_hook_disabled: Config.sales_hook_disabled?,
      last_orders_pull_path: last_orders_pull_path,
      debts_path: debts_path
    )
  end

  def noop
    render inertia: "Dashboard/Noop"
  end
end
