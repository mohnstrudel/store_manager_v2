# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: purchase_expenses
#
#  id               :bigint           not null, primary key
#  amount           :decimal(8, 2)    not null
#  description      :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  purchase_item_id :bigint           not null
#
RSpec.describe PurchaseExpense do
  let(:purchase) { create(:purchase) }
  let!(:first_item) { create(:purchase_item, purchase:, expenses: 0) }
  let!(:second_item) { create(:purchase_item, purchase:, expenses: 0) }
  let!(:third_item) { create(:purchase_item, purchase:, expenses: 0) }

  it "requires a purchase item" do
    expense = build(:purchase_expense, purchase_item: nil)

    expect(expense).not_to be_valid
    expect(expense.errors[:purchase_item]).to include("must exist")
  end

  it "adds an expense only to its selected item and derives the purchase total" do
    create(:purchase_expense, purchase_item: second_item, description: "Damaged packaging", amount: 4.25)

    expect(first_item.reload.expenses).to eq(0)
    expect(second_item.reload.expenses).to eq(BigDecimal("4.25"))
    expect(third_item.reload.expenses).to eq(0)
    expect(purchase.expenses_total).to eq(BigDecimal("4.25"))
  end

  it "does not allow its purchase item to change" do
    expense = create(:purchase_expense, purchase_item: first_item)

    expect(expense.update(purchase_item: second_item)).to be false
    expect(expense.errors[:purchase_item]).to include("cannot be changed")
    expect(expense.reload.purchase_item).to eq(first_item)
  end

  it "associates its audit with the purchase reached through its item" do
    expense = create(:purchase_expense, purchase_item: first_item)

    expect(expense.audits.last.associated).to eq(purchase)
  end

  it "recalculates the cached item total after update and destroy" do
    expense = create(:purchase_expense, purchase_item: first_item, amount: 4.25)
    create(:purchase_expense, purchase_item: first_item, amount: 2)

    expense.update!(amount: 5)
    expect(first_item.reload.expenses).to eq(BigDecimal("7"))

    expense.destroy!
    expect(first_item.reload.expenses).to eq(BigDecimal("2"))
  end
end
