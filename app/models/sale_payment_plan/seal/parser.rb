# frozen_string_literal: true

class SalePaymentPlan::Seal::Parser
  def self.parse(subscription, selling_plans_by_id:)
    new(subscription, selling_plans_by_id:).parse
  end

  def initialize(subscription, selling_plans_by_id:)
    @subscription = subscription
    @selling_plans_by_id = selling_plans_by_id
  end

  def parse
    {
      attributes: {
        provider: "seal",
        external_id: subscription.fetch("id").to_s,
        external_origin_order_id: subscription["order_id"],
        kind: plan_kind,
        status: subscription["status"].to_s.downcase.presence,
        expected_parts:,
        deposit_percent:,
        projected_total:,
        currency: subscription["currency"],
        next_due_at:
      },
      parts: part_snapshots
    }
  end

  private

  attr_reader :selling_plans_by_id, :subscription

  def expected_parts
    @expected_parts ||= Integer(subscription["billing_max_cycles"])
  rescue ArgumentError, TypeError
    1
  end

  def plan_kind
    deposit_percent ? "deposit" : "installments"
  end

  def deposit_percent
    return unless expected_parts == 1

    payment_percent
  end

  def payment_percent
    return @payment_percent if defined?(@payment_percent)

    percentages = subscription_items.map do |item|
      plan = selling_plan_for(item)
      next unless plan&.[]("pricing_policy_fixed_adjustment_type") == "PERCENTAGE"

      100.to_d - plan["pricing_policy_fixed_adjustment_value"].to_d
    end

    @payment_percent = percentages.first if percentages.none?(&:nil?) && percentages.uniq.one?
  end

  def projected_total
    return unless unambiguous_pricing?

    SalePaymentPlan.projected_deposit_total(
      deposit_merchandise_amount: subscription_items.sum { |item| item["final_amount"].to_d },
      deposit_percent: payment_percent,
      shipping_amount:
    )
  end

  def unambiguous_pricing?
    subscription_items.present? &&
      subscription_items.none? { |item|
        item["is_one_time_item"].to_i == 1 || Array(item["cycle_discounts"]).present?
      } &&
      payment_percent&.positive?
  end

  def shipping_amount
    (
      subscription["delivery_price_discounted"].presence ||
      subscription["delivery_price"]
    ).to_d
  end

  def subscription_items
    @subscription_items ||= Array(subscription["items"])
  end

  def selling_plan_for(item)
    selling_plans_by_id[item["selling_plan_id"].to_s]
  end

  def part_snapshots
    completed = completed_attempts
    scheduled = scheduled_attempts
    recurring_amount = subscription_items.sum { |item| item["final_amount"].to_d }

    (1..expected_parts).map do |sequence|
      attempt = sequence == 1 ? nil : completed[sequence - 2]
      scheduled_attempt = scheduled[sequence - completed.size - 2] if sequence > completed.size + 1

      {
        provider_part_id: "#{subscription.fetch("id")}:#{sequence}",
        sequence:,
        external_order_id: sequence == 1 ? subscription["order_id"] : attempt&.dig("order_id"),
        amount: recurring_amount,
        currency: subscription["currency"],
        due_at: parse_datetime(scheduled_attempt&.dig("date")),
        provider_completed_at: parse_datetime(attempt&.dig("completed_at"))
      }
    end
  end

  def completed_attempts
    @completed_attempts ||= Array(subscription["billing_attempts"])
      .select { |attempt| attempt["order_id"].present? && attempt["completed_at"].present? }
      .sort_by { |attempt| [attempt["completed_at"].to_s, attempt["id"].to_i] }
      .uniq { |attempt| attempt["order_id"].to_s }
      .first(expected_parts - 1)
  end

  def scheduled_attempts
    @scheduled_attempts ||= Array(subscription["billing_attempts"])
      .select { |attempt|
        attempt["order_id"].blank? &&
          attempt["completed_at"].blank? &&
          attempt["date"].present? &&
          attempt["status"].to_s.downcase != "failed"
      }
      .sort_by { |attempt| [attempt["date"].to_s, attempt["id"].to_i] }
  end

  def next_due_at
    parse_datetime(scheduled_attempts.first&.dig("date"))
  end

  def parse_datetime(value)
    DateTime.parse(value) if value.present?
  rescue ArgumentError
    nil
  end
end
