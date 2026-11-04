# frozen_string_literal: true

class ExpenseRates::EditResource < ApplicationResource
  typelize "ExpenseRate"
  attribute :expenseRate do |page|
    ExpenseRateResource.new(page.fetch(:expense_rate)).serializable_hash
  end
end
