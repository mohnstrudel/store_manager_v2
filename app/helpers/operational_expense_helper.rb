# frozen_string_literal: true

module OperationalExpenseHelper
  def operational_expense_props(expense)
    {id: expense.id, incurred_on: expense.incurred_on.iso8601, category: expense.category, amount: format_money(expense.amount),
     note: expense.note.to_s, expense_rate_id: expense.expense_rate_id}
  end

  def operational_expense_form_props(expense)
    {
      operationalExpense: operational_expense_props(expense),
      expenseRates: operational_expense_rate_options.map { |rate| expense_rate_props(rate) }
    }
  end

  def operational_expense_comparison_props(report = OperationalExpenseReport.new)
    report.rows.map do |row|
      {
        month: row[:month].iso8601,
        revenue: format_money(row[:revenue]),
        assumed_total: format_money(row[:assumed_total]),
        actual_total: format_money(row[:actual_total]),
        comparison: {
          amount: format_money(row[:comparison][:amount]),
          relation: row[:comparison][:relation].to_s
        },
        by_rate: row[:by_rate].map { |entry| entry.merge(assumed: format_money(entry[:assumed]), actual: format_money(entry[:actual])) }
      }
    end
  end

  def operational_expense_rate_options
    ExpenseRate.ordered
  end
end
