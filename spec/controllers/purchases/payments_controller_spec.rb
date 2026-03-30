# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchases::PaymentsController do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    let(:purchase) { create(:purchase) }

    context "with valid params" do
      it "creates a payment and redirects back to the purchase" do # rubocop:disable RSpec/MultipleExpectations
        payment_date = Date.new(2026, 3, 30)

        expect {
          post :create, params: {purchase_id: purchase.id, payment: {value: 10, payment_date: payment_date}}
        }.to change(Payment, :count).by(1)

        expect(response).to redirect_to(purchase_path(purchase))
        expect(Payment.last.purchase_id).to eq(purchase.id)
        expect(Payment.last.payment_date.to_date).to eq(payment_date)
      end
    end

    context "with invalid params" do
      it "does not create payment and returns unprocessable content" do # rubocop:disable RSpec/MultipleExpectations
        expect {
          post :create, params: {purchase_id: purchase.id, payment: {value: nil}}
        }.not_to change(Payment, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH #update" do
    let(:purchase) { create(:purchase) }
    let(:payment) { create(:payment, purchase:, value: 10) }

    it "updates the payment and redirects back to the purchase" do # rubocop:disable RSpec/MultipleExpectations
      payment_date = Date.new(2026, 4, 1)

      patch :update, params: {purchase_id: purchase.id, id: payment.id, payment: {value: 25, payment_date: payment_date}}

      expect(response).to redirect_to(purchase_path(purchase))
      expect(payment.reload.value).to eq(BigDecimal(25))
      expect(payment.payment_date.to_date).to eq(payment_date)
    end
  end

  describe "DELETE #destroy" do
    let(:purchase) { create(:purchase) }
    let!(:payment) { create(:payment, purchase:) }

    it "removes the payment and redirects back to the purchase" do # rubocop:disable RSpec/MultipleExpectations
      expect {
        delete :destroy, params: {purchase_id: purchase.id, id: payment.id}
      }.to change(Payment, :count).by(-1)

      expect(response).to redirect_to(purchase_path(purchase))
    end
  end
end
