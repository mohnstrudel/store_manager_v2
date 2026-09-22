# frozen_string_literal: true

class DropOperationalExpenses < ActiveRecord::Migration[8.1]
  def change
    drop_table :operational_expenses do |t|
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :category, null: false
      t.bigint :expense_rate_id
      t.date :incurred_on, null: false
      t.string :note
      t.timestamps

      t.index :expense_rate_id
      t.index :incurred_on
    end
  end
end
