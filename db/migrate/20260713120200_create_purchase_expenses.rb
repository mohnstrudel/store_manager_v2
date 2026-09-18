# frozen_string_literal: true

class CreatePurchaseExpenses < ActiveRecord::Migration[8.0]
  def up
    create_table :purchase_expenses do |t|
      t.references :purchase_item, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.timestamps
    end

    PurchaseItem.where.not(expenses: [nil, 0]).find_each do |item|
      PurchaseExpense.create!(purchase_item: item,
        description: "Legacy direct expense", amount: item.expenses)
    end
  end

  def down
    drop_table :purchase_expenses
  end
end
