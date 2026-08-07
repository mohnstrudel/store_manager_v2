# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseItems::ExpensesController do
  before { sign_in_as_admin }
  after { log_out }

  it "creates an item-level named expense" do
    item = create(:purchase_item)

    expect {
      post :create, params: {purchase_item_id: item.id, purchase_expense: {description: "Damaged packaging", amount: 4.25}}
    }.to change(PurchaseExpense, :count).by(1)

    expect(response).to redirect_to(purchase_path(item.purchase))
    expect(item.reload.expenses).to eq(BigDecimal("4.25"))
  end

  it "updates an item-level named expense" do
    item = create(:purchase_item)
    expense = create(:purchase_expense, purchase_item: item, amount: 4.25)

    patch :update, params: {
      purchase_item_id: item.id,
      id: expense.id,
      purchase_expense: {description: "Repacked", amount: 5}
    }

    expect(response).to redirect_to(purchase_path(item.purchase))
    expect(expense.reload).to have_attributes(description: "Repacked", amount: BigDecimal("5"))
  end

  it "redirects invalid item-level expenses to the purchase show page" do
    item = create(:purchase_item)

    post :create, params: {
      purchase_item_id: item.id,
      purchase_expense: {description: "", amount: 4.25},
      return_to: purchases_path
    }

    expect(response).to redirect_to(purchase_path(item.purchase))
  end

  it "destroys an item-level named expense and redirects back" do
    item = create(:purchase_item)
    expense = create(:purchase_expense, purchase_item: item, amount: 4.25)

    expect {
      delete :destroy, params: {purchase_item_id: item.id, id: expense.id}
    }.to change(PurchaseExpense, :count).by(-1)

    expect(response).to redirect_to(purchase_path(item.purchase))
    expect(item.reload.expenses).to eq(0)
  end

  it "denies managers" do
    item = create(:purchase_item)
    log_out
    sign_in create(:user, :manager)

    post :create, params: {purchase_item_id: item.id, purchase_expense: {description: "Damaged packaging", amount: 4.25}}

    expect(response).to redirect_to(noop_path)
  end

  it "does not update an expense through a different item" do
    item = create(:purchase_item)
    other_item = create(:purchase_item)
    expense = create(:purchase_expense, purchase_item: item)

    expect {
      patch :update, params: {
        purchase_item_id: other_item.id,
        id: expense.id,
        purchase_expense: {amount: 99}
      }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
