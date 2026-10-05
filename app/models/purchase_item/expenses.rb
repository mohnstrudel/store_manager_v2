# frozen_string_literal: true

module PurchaseItem::Expenses
  extend ActiveSupport::Concern

  included do
    after_create_commit :recalculate_expenses!
  end

  def recalculate_expenses!
    update_column(:expenses, purchase_expenses.sum(:amount))
  end
end
