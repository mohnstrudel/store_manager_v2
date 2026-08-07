# frozen_string_literal: true

# Order-level profitability: uses the sale's own Shopify money totals for
# revenue (authoritative order-level amounts) and aggregates purchase cost
# from the linked purchase items via SaleItem::Profitability.
module Sale::Profitability
  extend ActiveSupport::Concern

  def profitability(expense_fraction: ExpenseRate.combined_fraction)
    items = sale_items.includes(purchase_items: :purchase).to_a
    purchase_cost = items.sum(0.to_d, &:purchase_cost)
    direct_expenses = items.sum(0.to_d, &:direct_expenses)
    business_expenses = (expected_revenue.to_d * expense_fraction).round(2)

    {
      expected_revenue: expected_revenue.to_d,
      received_revenue: received_revenue.to_d,
      outstanding_revenue: outstanding_revenue.to_d,
      refunded_revenue: refunded_revenue.to_d,
      purchase_cost:,
      direct_expenses:,
      # What the goods themselves cost, once the named direct expenses are taken
      # out of the cost of goods. Revenue − merchandise − direct − OpEx then adds
      # up to the profit instead of charging the expenses twice.
      merchandise_cost: purchase_cost - direct_expenses,
      business_expenses:,
      realized_profit: received_revenue.to_d - purchase_cost - business_expenses,
      expected_final_profit: expected_revenue.to_d - purchase_cost - business_expenses,
      # A lone sale has no contract value to project against, so these carry
      # explicit nil rather than being absent — the plan scope (see
      # SalePaymentPlan#profitability) can populate them, and the frontend
      # type stays `T | null` on both branches instead of `T | undefined`.
      projected_revenue: nil,
      projected_business_expenses: nil,
      projected_final_profit: nil
    }
  end

  # The economics worth reporting for this order, and how wide they reach.
  #
  # A charge that belongs to exactly one payment plan is half of a larger deal:
  # only the originating order carries purchase links, so on its own a follow-up
  # charge would show its whole revenue as profit while the originating order
  # showed the plan's entire cost against a deposit. Several plans have no single
  # answer, so the order speaks for itself again.
  def profitability_summary(expense_fraction: ExpenseRate.combined_fraction)
    return if cancelled?

    plans = payment_plans_for_display

    if plans.one?
      plans.first.profitability(expense_fraction:).merge(scope: :plan)
    else
      profitability(expense_fraction:).merge(scope: :sale)
    end
  end
end
