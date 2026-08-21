# frozen_string_literal: true

# Per-item profitability based on Shopify money amounts allocated to this
# sale item, the linked purchase items' costs, and the configured
# percentage-based expense rates.
module SaleItem::Profitability
  extend ActiveSupport::Concern

  # The full cost of goods: purchase price, inbound shipping, and the ad-hoc
  # expenses booked against the purchase item. Direct expenses are part of it,
  # not an extra deduction on top.
  def purchase_cost
    purchase_items.sum(0.to_d) { |purchase_item| purchase_item.cost.to_d + purchase_item.expenses.to_d }
  end

  # What the suppliers charged for the goods themselves, before anything spent
  # landing them.
  def item_price_total
    purchase_items.sum(0.to_d) { |purchase_item| purchase_item.purchase.item_price.to_d }
  end

  def purchase_shipping_cost
    purchase_items.sum(0.to_d) { |purchase_item| purchase_item.shipping_cost.to_d }
  end

  # The share of purchase_cost that is ad-hoc expenses, so a summary can name it
  # without deducting it twice.
  def direct_expenses
    purchase_items.sum(0.to_d) { |purchase_item| purchase_item.expenses.to_d }
  end

  def business_expenses(expense_fraction = ExpenseRate.combined_fraction)
    (expected_revenue.to_d * expense_fraction).round(2)
  end

  def realized_profit(expense_fraction = ExpenseRate.combined_fraction)
    received_revenue.to_d - purchase_cost - business_expenses(expense_fraction)
  end

  def expected_final_profit(expense_fraction = ExpenseRate.combined_fraction)
    expected_revenue.to_d - purchase_cost - business_expenses(expense_fraction)
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
end
