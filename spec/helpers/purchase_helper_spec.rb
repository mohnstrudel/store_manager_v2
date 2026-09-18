# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseHelper do
  describe "#purchase_expense_props" do
    it "serializes amounts without insignificant trailing zeroes" do
      purchase_item = create(:purchase_item)
      expense = create(:purchase_expense, purchase_item:, amount: BigDecimal("10.00"))

      expect(helper.purchase_expense_props(expense, purchase_item:)[:amount]).to eq("10")

      expense.update!(amount: BigDecimal("10.50"))
      expect(helper.purchase_expense_props(expense, purchase_item:)[:amount]).to eq("10.5")
    end
  end

  describe "#unsaved_purchase_expense_props" do
    it "returns a blank amount for a new, unsaved expense" do
      purchase_item = create(:purchase_item)

      expect(helper.unsaved_purchase_expense_props(purchase_item:)[:amount]).to eq("")
    end
  end
end
