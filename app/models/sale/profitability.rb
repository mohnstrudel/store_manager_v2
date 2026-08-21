# frozen_string_literal: true

# Order-level profitability: uses the sale's own Shopify money totals for
# revenue (authoritative order-level amounts) and aggregates purchase cost
# from the linked purchase items via SaleItem::Profitability.
module Sale::Profitability
  extend ActiveSupport::Concern

  # Terms a payment plan can add up across its sales. Everything else is
  # derived from them once, by `derived`, so a plan states one equation
  # instead of summing figures that were already netted per charge.
  ADDITIVE_TERMS = %i[
    expected_revenue
    collected_revenue
    item_price_total
    purchase_shipping_cost
    direct_expenses
    purchase_paid
  ].freeze

  # The one equation behind the economics card, for a lone sale and for a whole
  # payment plan alike. Gross revenue is passed in because only the plan knows
  # the contract value; every deduction follows from it, OpEx included, so a
  # deposit is never measured against 100% of the cost.
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

  # Money the customer paid and we still hold. A store can state an order's
  # value without ever stating how much of it was collected, and no cash
  # figure can be claimed from that.
  def collected_revenue
    return if payment_split_unknown?

    received_revenue.to_d - refunded_revenue.to_d
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

  private

  # Supplier money behind this order's units only. A purchase pays for every
  # unit it ordered, and the rest can sit in a warehouse or belong to another
  # customer, so each purchase gives up a per-unit share and never more than
  # it was actually paid.
  def supplier_paid(items)
    items.flat_map(&:purchase_items).group_by(&:purchase).sum(0.to_d) { |purchase, linked|
      units = purchase.amount.to_i
      paid = purchase.paid.to_d

      units.zero? ? 0.to_d : [paid * linked.size / units, paid].min
    }
  end
end
