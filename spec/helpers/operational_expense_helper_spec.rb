# frozen_string_literal: true

require "rails_helper"

RSpec.describe OperationalExpenseHelper do
  it "serializes the comparison relation without exposing signed formatted deltas" do
    report = instance_double(
      OperationalExpenseReport,
      rows: [
        {
          month: Date.new(2026, 7, 1),
          revenue: BigDecimal("100"),
          assumed_total: BigDecimal("20"),
          actual_total: BigDecimal("10"),
          comparison: {amount: BigDecimal("10"), relation: :under},
          by_rate: []
        }
      ]
    )

    row = helper.operational_expense_comparison_props(report).first

    expect(row[:comparison]).to eq({amount: "10", relation: "under"})
    expect(row).not_to have_key(:delta)
  end

  describe "#operational_expense_props" do
    it "serializes an expense record" do
      rate = create(:expense_rate)
      expense = create(:operational_expense, category: "Rent", amount: 500, note: "May rent", expense_rate: rate)

      props = helper.operational_expense_props(expense)

      expect(props).to include(
        id: expense.id,
        incurred_on: expense.incurred_on.iso8601,
        category: "Rent",
        note: "May rent",
        expense_rate_id: rate.id
      )
    end
  end

  describe "#operational_expense_rate_options" do
    it "returns all rates, ordered" do
      first = create(:expense_rate, rate_percent: 20)
      second = create(:expense_rate, rate_percent: 5)

      expect(helper.operational_expense_rate_options).to eq([first, second])
    end
  end

  describe "#operational_expense_form_props" do
    it "nests the expense props and rate options" do
      rate = create(:expense_rate)
      expense = build(:operational_expense, expense_rate: rate)

      props = helper.operational_expense_form_props(expense)

      expect(props[:operationalExpense]).to include(category: expense.category)
      expect(props[:expenseRates].pluck(:id)).to include(rate.id)
    end
  end
end
