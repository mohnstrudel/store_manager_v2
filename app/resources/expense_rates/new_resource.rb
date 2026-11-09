# frozen_string_literal: true

class ExpenseRates::NewResource < ApplicationResource
  typelize({name: :string, rate_percent: :number})
  attribute :expenseRate do |page|
    expense_rate = page.fetch(:expense_rate)

    {name: expense_rate.name.to_s, rate_percent: expense_rate.rate_percent.to_f}
  end
end
