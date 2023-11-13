class DashboardController < ApplicationController
  def index
  end

  def debts
    @unpaid_purchases = Purchase.unpaid
    @sales_trends = ProductSale.sales_trends
  end
end
