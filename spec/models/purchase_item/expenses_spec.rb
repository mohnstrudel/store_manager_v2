# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItem::Expenses do
  describe "cross-purchase reassignment" do
    it "carries item expenses to the new purchase" do
      old_purchase = create(:purchase)
      new_purchase = create(:purchase)
      item = create(:purchase_item, purchase: old_purchase, expenses: 0)
      expense = create(:purchase_expense, purchase_item: item, description: "Customs", amount: 10)

      item.update!(purchase_id: new_purchase.id)

      expect(expense.reload.purchase).to eq(new_purchase)
      expect(item.reload.expenses).to eq(BigDecimal("10"))
      expect(old_purchase.expenses_total).to eq(BigDecimal("0"))
      expect(new_purchase.expenses_total).to eq(BigDecimal("10"))
    end

    it "does not corrupt the moved item's expense record, allowing it to still be edited afterwards" do
      old_purchase = create(:purchase)
      new_purchase = create(:purchase)
      item = create(:purchase_item, purchase: old_purchase, expenses: 0)
      expense = create(:purchase_expense, purchase_item: item, description: "Customs", amount: 10)

      item.update!(purchase_id: new_purchase.id)
      expense.reload

      expect(expense.update(amount: 15)).to be true
      expect(item.reload.expenses).to eq(BigDecimal("15"))
    end
  end

  describe "destruction" do
    it "removes item expenses and lowers the surviving purchase total" do
      purchase = create(:purchase)
      item = create(:purchase_item, purchase:)
      create(:purchase_expense, purchase_item: item, amount: 10)

      expect { item.destroy! }.to change(PurchaseExpense, :count).by(-1)
      expect(purchase.expenses_total).to eq(BigDecimal("0"))
    end

    it "allows a purchase with item expenses to be destroyed" do
      purchase = create(:purchase)
      item = create(:purchase_item, purchase:)
      create(:purchase_expense, purchase_item: item, amount: 10)

      expect { purchase.destroy! }.to change(PurchaseExpense, :count).by(-1)
      expect(Purchase.exists?(purchase.id)).to be false
    end
  end
end
