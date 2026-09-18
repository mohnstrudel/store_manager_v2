# frozen_string_literal: true

module SaleItem::Profitability
  extend ActiveSupport::Concern

  def item_price_total
    purchase_items.sum(0.to_d) { |purchase_item| purchase_item.purchase.item_price.to_d }
  end

  def purchase_shipping_cost
    purchase_items.sum(0.to_d) { |purchase_item| purchase_item.shipping_cost.to_d }
  end

  def direct_expenses
    purchase_items.sum(0.to_d) { |purchase_item| purchase_item.expenses.to_d }
  end

  def realized_profit(expense_fraction = ExpenseRate.combined_fraction)
    received_revenue.to_d - purchase_cost - business_expenses(expense_fraction)
  end

  def purchase_cost
    purchase_items.sum(0.to_d) { |purchase_item| purchase_item.cost.to_d + purchase_item.expenses.to_d }
  end

  def business_expenses(expense_fraction = ExpenseRate.combined_fraction)
    (expected_revenue.to_d * expense_fraction).round(2)
  end

  def future_revenue
    outstanding_revenue.to_d
  end

  def profitability_status(expense_fraction = ExpenseRate.combined_fraction)
    return :unknown if expected_revenue.nil?

    profit = expected_final_profit(expense_fraction)

    if profit.positive?
      :profitable
    elsif profit.negative?
      :loss
    else
      :break_even
    end
  end

  def expected_final_profit(expense_fraction = ExpenseRate.combined_fraction)
    expected_revenue.to_d - purchase_cost - business_expenses(expense_fraction)
  end
end
