# frozen_string_literal: true

class ExpenseRatesController < ApplicationController
  before_action :set_expense_rate, only: %i[edit update destroy]

  def index
    @expense_rates = ExpenseRate.ordered
    last_modified = [
      @expense_rates.maximum(:updated_at),
      OperationalExpense.maximum(:updated_at),
      Sale.maximum(:updated_at)
    ].compact.max

    return unless stale?(etag: [@expense_rates, request.inertia?, ViteRuby.digest], last_modified:)

    render inertia: "ExpenseRates/Index", props: {
      expenseRates: @expense_rates.map { |expense_rate| helpers.expense_rate_props(expense_rate) },
      comparison: helpers.operational_expense_comparison_props
    }
  end

  def new
    @expense_rate = ExpenseRate.new

    render inertia: "ExpenseRates/New", props: helpers.expense_rate_form_props(@expense_rate)
  end

  def edit
    render inertia: "ExpenseRates/Edit", props: helpers.expense_rate_form_props(@expense_rate)
  end

  def create
    @expense_rate = ExpenseRate.new(expense_rate_params)

    if @expense_rate.save
      redirect_to expense_rates_url, notice: "OpEx rate was successfully created"
    else
      redirect_to new_expense_rate_url, inertia: inertia_errors(@expense_rate.errors)
    end
  end

  def update
    if @expense_rate.update(expense_rate_params)
      redirect_to expense_rates_url, notice: "OpEx rate was successfully updated"
    else
      redirect_to edit_expense_rate_url(@expense_rate), inertia: inertia_errors(@expense_rate.errors)
    end
  end

  def destroy
    @expense_rate.destroy

    redirect_to expense_rates_url, notice: "OpEx rate was successfully destroyed"
  end

  private

  def set_expense_rate
    @expense_rate = ExpenseRate.find(params.expect(:id))
  end

  def expense_rate_params
    params.fetch(:expense_rate, {}).permit(:name, :rate_percent)
  end
end
