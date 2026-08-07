# frozen_string_literal: true

module PurchaseItems
  class ExpensesController < ApplicationController
    before_action :set_purchase_item
    before_action :set_expense, only: %i[update destroy]

    def create
      @purchase_expense = @purchase_item.purchase_expenses.new(expense_params)
      return redirect_to return_path, notice: "Item direct expense was successfully created", status: :see_other if @purchase_expense.save

      redirect_to failure_path, inertia: inertia_errors(@purchase_expense.errors)
    end

    def update
      return redirect_to return_path, notice: "Item direct expense was successfully updated", status: :see_other if @purchase_expense.update(expense_params)

      redirect_to failure_path, inertia: inertia_errors(@purchase_expense.errors)
    end

    def destroy
      @purchase_expense.destroy!
      redirect_to return_path, notice: "Item direct expense was successfully removed", status: :see_other
    end

    private

    def authorize_resource
      authorize :purchase_expense, :create?
    end

    def set_purchase_item
      @purchase_item = PurchaseItem.find(params.expect(:purchase_item_id))
      @purchase = @purchase_item.purchase
    end

    def set_expense
      @purchase_expense = @purchase_item.purchase_expenses.find(params.expect(:id))
    end

    def expense_params
      params.expect(purchase_expense: [:description, :amount])
    end

    def return_path
      params[:return_to].presence || purchase_path(@purchase)
    end

    def failure_path
      purchase_path(@purchase)
    end
  end
end
