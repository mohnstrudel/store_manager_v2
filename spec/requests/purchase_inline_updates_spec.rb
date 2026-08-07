# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase inline updates" do
  before { sign_in_as_admin }

  describe "payment errors" do
    it "creates a payment, persists it, and honors return_to" do
      purchase = create(:purchase)
      payment_date = Date.new(2026, 6, 1)

      expect {
        post purchase_payments_path(purchase), params: {
          payment: {value: 12.5, payment_date:},
          return_to: purchases_path
        }
      }.to change(Payment, :count).by(1)

      expect_successful_return_to(purchases_path)
      expect(Payment.last).to have_attributes(purchase:, payment_date: payment_date, value: BigDecimal("12.5"))
    end

    it "returns failed creates to the purchase show page with Inertia errors" do
      purchase = create(:purchase)

      post purchase_payments_path(purchase), params: {
        payment: {value: nil},
        return_to: purchases_path
      }

      expect_purchase_show_error(purchase, :value)
    end

    it "updates a payment, persists it, and honors return_to" do
      purchase = create(:purchase)
      payment = create(:payment, purchase:, value: 10)
      payment_date = Date.new(2026, 6, 2)

      patch purchase_payment_path(purchase, payment), params: {
        payment: {value: 15, payment_date:},
        return_to: purchases_path
      }

      expect_successful_return_to(purchases_path)
      expect(payment.reload).to have_attributes(payment_date: payment_date, value: BigDecimal("15"))
    end

    it "returns failed updates to the purchase show page with Inertia errors" do
      purchase = create(:purchase)
      payment = create(:payment, purchase:)

      patch purchase_payment_path(purchase, payment), params: {
        payment: {value: nil, payment_date: payment.payment_date},
        return_to: purchases_path
      }

      expect_purchase_show_error(purchase, :value)
    end
  end

  describe "item-level expense errors" do
    it "creates an item expense, persists it, and honors return_to" do
      item = create(:purchase_item)

      expect {
        post purchase_item_expenses_path(item), params: {
          purchase_expense: {description: "Repacking", amount: 4.25},
          return_to: purchases_path
        }
      }.to change(PurchaseExpense, :count).by(1)

      expect_successful_return_to(purchases_path)
      expect(PurchaseExpense.last).to have_attributes(
        purchase: item.purchase,
        purchase_item: item,
        description: "Repacking",
        amount: BigDecimal("4.25")
      )
    end

    it "returns failed creates to the purchase show page with Inertia errors" do
      item = create(:purchase_item)

      post purchase_item_expenses_path(item), params: {
        purchase_expense: {description: "", amount: 10},
        return_to: purchases_path
      }

      expect_purchase_show_error(item.purchase, :description)
    end

    it "updates an item expense, persists it, and honors return_to" do
      item = create(:purchase_item)
      expense = create(:purchase_expense, purchase_item: item, amount: 4.25)

      patch purchase_item_expense_path(item, expense), params: {
        purchase_expense: {description: "Repacking", amount: 5},
        return_to: purchases_path
      }

      expect_successful_return_to(purchases_path)
      expect(expense.reload).to have_attributes(description: "Repacking", amount: BigDecimal("5"))
    end

    it "returns failed updates to the purchase show page with Inertia errors" do
      item = create(:purchase_item)
      expense = create(:purchase_expense, purchase_item: item)

      patch purchase_item_expense_path(item, expense), params: {
        purchase_expense: {description: "", amount: expense.amount},
        return_to: purchases_path
      }

      expect_purchase_show_error(item.purchase, :description)
    end
  end

  private

  def expect_successful_return_to(path)
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(path)
  end

  def expect_purchase_show_error(purchase, attribute)
    expect(response).to redirect_to(purchase_path(purchase))

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect_inertia.to render_component("Purchases/Show")
    expect(inertia.props[:errors][attribute]).to eq("can't be blank")
  end
end
