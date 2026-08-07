# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OperationalExpenses" do
  before { sign_in_as_admin }

  describe "GET /operational_expenses" do
    it "renders the index with the ledger" do
      expense = create(:operational_expense, category: "Rent", amount: 500)

      get operational_expenses_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("OperationalExpenses/Index")
      expect(inertia.props[:operationalExpenses].pluck(:id)).to include(expense.id)
    end

    it "denies managers access to the ledger" do
      log_out
      sign_in(create(:user, :manager))

      get operational_expenses_path

      expect(response).to redirect_to(noop_path)
    end
  end

  describe "GET /operational_expenses/new" do
    it "renders the new form" do
      get new_operational_expense_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("OperationalExpenses/New")
    end
  end

  describe "GET /operational_expenses/:id/edit" do
    it "renders the edit form" do
      expense = create(:operational_expense)

      get edit_operational_expense_path(expense)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("OperationalExpenses/Edit")
      expect(inertia.props[:operationalExpense]).to include(id: expense.id)
    end
  end

  describe "POST /operational_expenses" do
    it "creates a signed actual expense" do
      expect {
        post operational_expenses_path, params: {operational_expense: {incurred_on: Date.new(2026, 6, 1), category: "Rebate", amount: -25}}
      }.to change(OperationalExpense, :count).by(1)

      expect(OperationalExpense.last.amount).to eq(BigDecimal("-25"))
      expect(response).to redirect_to(operational_expenses_path)
    end
  end

  describe "PATCH /operational_expenses/:id" do
    it "updates an expense" do
      expense = create(:operational_expense, category: "Rent")

      patch operational_expense_path(expense), params: {operational_expense: {category: "Warehouse rent"}}

      expect(expense.reload.category).to eq("Warehouse rent")
      expect(response).to redirect_to(operational_expenses_path)
    end
  end

  describe "DELETE /operational_expenses/:id" do
    it "destroys an expense" do
      expense = create(:operational_expense)

      expect {
        delete operational_expense_path(expense)
      }.to change(OperationalExpense, :count).by(-1)

      expect(response).to redirect_to(operational_expenses_path)
    end
  end
end
