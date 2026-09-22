# frozen_string_literal: true

module ExpenseRateHelper
  def expense_rate_form_props(expense_rate)
    {
      expenseRate: expense_rate_props(expense_rate)
    }
  end

  def expense_rate_props(expense_rate)
    {
      id: expense_rate.id,
      name: expense_rate.name.to_s,
      rate_percent: expense_rate.rate_percent.to_f
    }
  end
end
