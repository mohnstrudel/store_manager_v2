# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ExpenseRates" do
  before { sign_in_as_admin }

  describe "GET /expense_rates" do
    it "renders the index Inertia component with ordered rates" do
      first = create(:expense_rate, name: "Old Costs", rate_percent: 50)
      second = create(:expense_rate, name: "Payroll", rate_percent: 15)
      third = create(:expense_rate, name: "Advertising", rate_percent: 5)

      get expense_rates_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("ExpenseRates/Index")
      expect(inertia.props[:expenseRates].pluck(:id)).to eq([first.id, second.id, third.id])
      expect(inertia.props[:expenseRates].first).to include(
        name: "Old Costs",
        rate_percent: 50.0
      )
    end

    it "denies access to managers" do
      log_out
      sign_in create(:user, :manager)

      get expense_rates_path

      expect(response).to redirect_to(noop_path)
    end
  end

  describe "GET /expense_rates/new" do
    it "renders the new Inertia component" do
      get new_expense_rate_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("ExpenseRates/New")
      expect(inertia.props[:expenseRate]).to include(id: nil, name: "")
    end
  end

  describe "GET /expense_rates/:id/edit" do
    it "renders the edit Inertia component" do
      expense_rate = create(:expense_rate, name: "Payroll")

      get edit_expense_rate_path(expense_rate)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("ExpenseRates/Edit")
      expect(inertia.props[:expenseRate]).to include(id: expense_rate.id, name: "Payroll")
    end
  end

  describe "POST /expense_rates" do
    it "creates an expense rate and redirects to the index" do
      expect {
        post expense_rates_path, params: {expense_rate: {name: "Payroll", rate_percent: "15"}}
      }.to change(ExpenseRate, :count).by(1)

      expect(response).to redirect_to(expense_rates_url)
      expect(ExpenseRate.last).to have_attributes(name: "Payroll", rate_percent: BigDecimal("15"))
    end

    it "redirects back with errors for invalid params" do
      expect {
        post expense_rates_path, params: {expense_rate: {name: "", rate_percent: "150"}}
      }.not_to change(ExpenseRate, :count)

      expect(response).to redirect_to(new_expense_rate_url)
    end

    it "denies creation for managers" do
      log_out
      sign_in create(:user, :manager)

      expect {
        post expense_rates_path, params: {expense_rate: {name: "Payroll", rate_percent: "15"}}
      }.not_to change(ExpenseRate, :count)

      expect(response).to redirect_to(noop_path)
    end
  end

  describe "PATCH /expense_rates/:id" do
    it "updates the expense rate and redirects to the index" do
      expense_rate = create(:expense_rate, name: "Payroll", rate_percent: 15)

      patch expense_rate_path(expense_rate), params: {expense_rate: {rate_percent: "12.5"}}

      expect(response).to redirect_to(expense_rates_url)
      expect(expense_rate.reload).to have_attributes(rate_percent: BigDecimal("12.5"))
    end

    it "redirects back with errors for invalid params" do
      expense_rate = create(:expense_rate, name: "Payroll")

      patch expense_rate_path(expense_rate), params: {expense_rate: {rate_percent: ""}}

      expect(response).to redirect_to(edit_expense_rate_url(expense_rate))
    end
  end

  describe "DELETE /expense_rates/:id" do
    it "destroys the expense rate" do
      expense_rate = create(:expense_rate)

      expect {
        delete expense_rate_path(expense_rate)
      }.to change(ExpenseRate, :count).by(-1)

      expect(response).to redirect_to(expense_rates_url)
    end
  end
end
