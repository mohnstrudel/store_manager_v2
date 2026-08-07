# frozen_string_literal: true

# Compares signed, recorded operating costs with current percentage-based rates.
# Rates are intentionally recomputed for historical months; v1 has no versioning.
class OperationalExpenseReport
  def initialize(months: 12, ending_on: Time.zone.today)
    @months = months
    @ending_on = ending_on
  end

  def rows
    revenues = revenue_by_month
    actuals = actuals_by_month_and_rate_and_category
    rates = ExpenseRate.ordered.to_a

    month_starts.map do |month|
      revenue = revenues.fetch(month, 0.to_d)
      by_rate = rates.map do |rate|
        actual = actuals.dig(month, rate.id)&.values&.sum || 0.to_d
        assumed = (revenue * rate.rate_percent / 100).round(2)
        {label: rate.name, assumed:, actual:}
      end
      (actuals.dig(month, nil) || {}).each do |category, actual|
        by_rate << {label: "Unmatched · #{category}", assumed: 0.to_d, actual:}
      end
      assumed_total = by_rate.sum { |entry| entry[:assumed] }
      actual_total = by_rate.sum { |entry| entry[:actual] }
      comparison = compare_actual_with_estimate(actual_total, assumed_total)
      {month:, revenue:, assumed_total:, actual_total:, comparison:, by_rate:}
    end
  end

  private

  attr_reader :months, :ending_on

  def month_starts
    @month_starts ||= (0...months).map { |offset| (ending_on.beginning_of_month - (months - 1 - offset).months).to_date }
  end

  def revenue_by_month
    Sale.uncancelled
      .where(Sale.shop_created_expr.gteq(month_starts.first))
      .group(month_expr)
      .sum(:expected_revenue)
      .transform_keys(&:to_date)
      .transform_values(&:to_d)
  end

  def actuals_by_month_and_rate_and_category
    OperationalExpense.where(incurred_on: month_starts.first..ending_on.end_of_month)
      .group(:incurred_on, :expense_rate_id, :category)
      .sum(:amount)
      .each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |((date, rate_id, category), amount), rows|
        rows[date.beginning_of_month][rate_id] ||= {}
        rows[date.beginning_of_month][rate_id][category] = amount.to_d
      end
  end

  def compare_actual_with_estimate(actual, estimated)
    difference = actual - estimated
    relation = if difference.negative?
      :under
    elsif difference.positive?
      :over
    else
      :equal
    end

    {amount: difference.abs, relation:}
  end

  def month_expr
    Arel::Nodes::NamedFunction.new("DATE_TRUNC", [Arel::Nodes.build_quoted("month"), Sale.shop_created_expr])
  end
end
