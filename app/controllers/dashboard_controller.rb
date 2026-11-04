# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    render_inertia "Dashboard/Index", serializer: Dashboard::IndexResource,
      locals: {sale_debts: Product.with_sale_debts, suppliers_debts: Supplier.debt_summaries}
  end

  def noop
    render inertia: "Dashboard/Noop"
  end
end
