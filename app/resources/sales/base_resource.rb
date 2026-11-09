# frozen_string_literal: true

class Sales::BaseResource < SaleResource
  typelize({
    progress: :number,
    amounts_unknown: :boolean,
    paid: "string | null",
    price: "string | null",
    debt: "string | null",
    payment_overdue: :boolean
  })
  attribute :payment do |sale|
    pie = payment_pie_total(sale.expected_revenue, sale.received_revenue, sale.outstanding_revenue)

    {
      progress: [percent_of(sale.received_revenue, pie) || 0, 100].min,
      amounts_unknown: sale.payment_split_unknown?,
      paid: format_money(sale.received_revenue),
      price: format_money(pie),
      debt: format_money(sale.outstanding_revenue),
      payment_overdue: sale.payment_overdue
    }
  end

  typelize :boolean
  attribute :partially_paid do |sale|
    sale.payment_plans.empty? && sale.partially_paid?
  end

  typelize "Array<SalePaymentPlan>"
  attribute :payment_plans do |sale|
    SalePaymentPlanResource.new(sale.payment_plans, params: {sale:}).serializable_hash
  end
end
