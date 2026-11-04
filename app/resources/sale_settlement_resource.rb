# frozen_string_literal: true

class SaleSettlementResource < ApplicationResource
  typelize_from Sale

  EMPTY_PAYMENT_PROGRESS = {
    source: nil,
    percent: nil,
    paid: nil,
    total: nil,
    remaining: nil,
    completed_parts: nil,
    expected_parts: nil,
    sale_part_number: nil,
    plan_id: nil
  }.freeze

  typelize '"paid" | "not_fully_paid" | "unknown"', nullable: true
  attribute :settlement_status do |sale|
    sale.settlement_status unless sale.economically_excluded?
  end

  typelize({
    source: '"plan_deposit" | "plan_schedule" | "amount" | "woo_deposit" | "woo_unavailable" | null',
    percent: "number | null",
    paid: "string | null",
    total: "string | null",
    remaining: "string | null",
    completed_parts: "number | null",
    expected_parts: "number | null",
    sale_part_number: "number | null",
    plan_id: "number | null"
  }, nullable: true)
  attribute :payment_progress do |sale|
    payment_progress(sale) if !sale.economically_excluded? && (sale.paid? || sale.not_fully_paid?)
  end

  def payment_progress(sale)
    plans = sale.payment_plans

    if plans.one?
      plan_payment_progress(plans.first, sale)
    elsif sale.outstanding_revenue.nil? && sale.expected_revenue.present?
      woo_payment_progress(sale)
    else
      amount_payment_progress(sale)
    end
  end

  def plan_payment_progress(plan, sale)
    return amount_payment_progress(sale) if plan.projected_total.nil?

    remainder = plan.projected_remainder
    paid = plan.projected_total - remainder
    schedule = plan.kind != "deposit" && plan.expected_parts > 1

    EMPTY_PAYMENT_PROGRESS.merge(
      source: schedule ? "plan_schedule" : "plan_deposit",
      percent: [percent_of(paid, plan.projected_total) || 0, 100].min,
      paid: format_usd(paid),
      total: format_usd(plan.projected_total),
      remaining: format_usd(remainder),
      completed_parts: schedule ? plan.collected_parts : nil,
      expected_parts: schedule ? plan.expected_parts : nil,
      sale_part_number: schedule ? plan.part_number_for(sale) : nil,
      plan_id: plan.id
    )
  end

  def amount_payment_progress(sale)
    pie = payment_pie_total(sale.expected_revenue, sale.received_revenue, sale.outstanding_revenue)
    return EMPTY_PAYMENT_PROGRESS if pie.nil?

    EMPTY_PAYMENT_PROGRESS.merge(
      source: "amount",
      percent: [percent_of(sale.received_revenue, pie) || 0, 100].min,
      paid: format_usd(sale.received_revenue),
      total: format_usd(pie),
      remaining: sale.outstanding_revenue.to_d.positive? ? format_usd(sale.outstanding_revenue) : nil
    )
  end

  def woo_payment_progress(sale)
    EMPTY_PAYMENT_PROGRESS.merge(
      source: sale.received_revenue.present? ? "woo_deposit" : "woo_unavailable",
      paid: format_usd(sale.received_revenue),
      total: format_usd(sale.expected_revenue)
    )
  end
end
