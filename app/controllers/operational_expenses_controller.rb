# frozen_string_literal: true

class OperationalExpensesController < ApplicationController
  before_action :set_operational_expense, only: %i[edit update destroy]

  def index
    render inertia: "OperationalExpenses/Index", props: {
      operationalExpenses: policy_scope(OperationalExpense).recent_first.map { |expense| helpers.operational_expense_props(expense) }
    }
  end

  def new
    render inertia: "OperationalExpenses/New", props: helpers.operational_expense_form_props(OperationalExpense.new(incurred_on: Time.zone.today))
  end

  def edit
    render inertia: "OperationalExpenses/Edit", props: helpers.operational_expense_form_props(@operational_expense)
  end

  def create
    @operational_expense = OperationalExpense.new(operational_expense_params)
    return redirect_to operational_expenses_url, notice: "OpEx entry was successfully created" if @operational_expense.save

    redirect_to new_operational_expense_url, inertia: inertia_errors(@operational_expense.errors)
  end

  def update
    return redirect_to operational_expenses_url, notice: "OpEx entry was successfully updated" if @operational_expense.update(operational_expense_params)

    redirect_to edit_operational_expense_url(@operational_expense), inertia: inertia_errors(@operational_expense.errors)
  end

  def destroy
    @operational_expense.destroy
    redirect_to operational_expenses_url, notice: "OpEx entry was successfully deleted"
  end

  private

  def authorize_resource
    authorize :operational_expense
  end

  def set_operational_expense
    @operational_expense = policy_scope(OperationalExpense).find(params.expect(:id))
  end

  def operational_expense_params
    params.fetch(:operational_expense, {}).permit(:incurred_on, :category, :amount, :note, :expense_rate_id)
  end
end
