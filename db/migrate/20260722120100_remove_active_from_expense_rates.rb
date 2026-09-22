# frozen_string_literal: true

class RemoveActiveFromExpenseRates < ActiveRecord::Migration[8.1]
  def change
    remove_column :expense_rates, :active, :boolean, default: true, null: false
  end
end
