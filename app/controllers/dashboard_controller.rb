# frozen_string_literal: true

class DashboardController < ApplicationController
  include DashboardDebtReporting

  def index
    @suppliers_debts = Supplier
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
    @total_suppliers_debt = @suppliers_debts.pluck(:total_debt).sum
    @sale_debts = sale_debts
    @config = Config
  end

  def noop
  end
end
