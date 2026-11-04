# frozen_string_literal: true

class Purchases::ExpenseResource < ApplicationResource
  typelize_from PurchaseExpense

  attributes :id, :description

  typelize :string
  attribute :amount do |expense|
    compact_decimal_field_value(expense.amount)
  end

  typelize :string
  attribute :update_path do |expense|
    purchase_item_expense_path(params.fetch(:purchase_item), expense)
  end

  typelize :string
  attribute :destroy_path do |expense|
    purchase_item = params.fetch(:purchase_item)
    purchase_item_expense_path(purchase_item, expense, return_to: purchase_path(purchase_item.purchase))
  end
end
