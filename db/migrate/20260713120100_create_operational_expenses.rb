# frozen_string_literal: true

class CreateOperationalExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :operational_expenses do |t|
      t.date :incurred_on, null: false
      t.string :category, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :note
      t.references :expense_rate, foreign_key: true
      t.timestamps
    end

    add_index :operational_expenses, :incurred_on
  end
end
