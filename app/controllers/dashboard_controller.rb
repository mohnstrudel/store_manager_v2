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

    render_inertia "Dashboard/Index", serializer: Dashboard::IndexResource,
      locals: {sale_debts:, suppliers_debts:}
  end

  def noop
    render inertia: "Dashboard/Noop"
  end
end
