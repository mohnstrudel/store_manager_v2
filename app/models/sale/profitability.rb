# frozen_string_literal: true

module Sale::Profitability
  extend ActiveSupport::Concern

  ADDITIVE_TERMS = %i[
    expected_revenue
    collected_revenue
    item_price_total
    purchase_shipping_cost
    direct_expenses
    purchase_paid
  ].freeze

  def self.derived(terms, gross_revenue:, expense_fraction:)
    purchase_expenses = terms[:purchase_shipping_cost] + terms[:direct_expenses]
    business_expenses = (gross_revenue * expense_fraction).round(2)
    collected_revenue = terms[:collected_revenue]

    {
      gross_revenue:,
      purchase_expenses:,
      business_expenses:,
      net_profit: gross_revenue - terms[:item_price_total] - purchase_expenses - business_expenses,
      cash_position: collected_revenue && collected_revenue - terms[:purchase_paid]
    }
  end

  def profitability_summary(expense_fraction: ExpenseRate.combined_fraction)
    return if cancelled?

    plans = payment_plans_for_display

    if plans.one?
      plans.first.profitability(expense_fraction:).merge(scope: :plan)
    else
      profitability(expense_fraction:).merge(scope: :sale)
    end
  end

  def profitability(expense_fraction: ExpenseRate.combined_fraction)
    items = sale_items.includes(purchase_items: :purchase).to_a
    terms = {
      expected_revenue: expected_revenue.to_d,
      collected_revenue:,
      item_price_total: items.sum(0.to_d, &:item_price_total),
      purchase_shipping_cost: items.sum(0.to_d, &:purchase_shipping_cost),
      direct_expenses: items.sum(0.to_d, &:direct_expenses),
      purchase_paid: supplier_paid(items)
    }

    terms.merge(
      Sale::Profitability.derived(terms, gross_revenue: terms[:expected_revenue], expense_fraction:)
    )
  end

  def collected_revenue
    return if payment_split_unknown?

    received_revenue.to_d - refunded_revenue.to_d
  end

  private

  def supplier_paid(items)
    items.flat_map(&:purchase_items).group_by(&:purchase).sum(0.to_d) { |purchase, linked|
      units = purchase.amount.to_i
      paid = purchase.paid.to_d

      units.zero? ? 0.to_d : [paid * linked.size / units, paid].min
    }
  end
end
