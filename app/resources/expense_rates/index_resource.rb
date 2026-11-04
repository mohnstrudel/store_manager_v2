# frozen_string_literal: true

class ExpenseRates::IndexResource < ApplicationResource
  typelize "Array<ExpenseRate>"
  attribute :expenseRates do |page|
    ExpenseRateResource.new(page.fetch(:expense_rates)).serializable_hash
  end
end
