# frozen_string_literal: true

class ExpenseRateResource < ApplicationResource
  typelize_from ExpenseRate

  attributes :id, :name

  typelize :number
  attribute :rate_percent do |expense_rate|
    expense_rate.rate_percent.to_f
  end
end
