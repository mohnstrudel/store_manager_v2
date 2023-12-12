class DashboardController < ApplicationController
  def index
  end

  def debts
    @unpaid_purchases = Purchase.unpaid
    @sales_debt = ProductSale.sales_trends
  end
end
