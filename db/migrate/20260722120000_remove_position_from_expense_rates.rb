# frozen_string_literal: true

class RemovePositionFromExpenseRates < ActiveRecord::Migration[8.1]
  def change
    remove_column :expense_rates, :position, :integer
  end
end
