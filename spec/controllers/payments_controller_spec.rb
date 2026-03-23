# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    let(:purchase) { create(:purchase) }

    context "with valid params" do
      it "creates a payment and returns turbo stream success" do
        expect {
          post :create, params: {payment: {value: 10, purchase_id: purchase.id}}, format: :turbo_stream
        }.to change(Payment, :count).by(1)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "does not create payment and returns unprocessable content" do
        expect {
          post :create, params: {payment: {value: nil, purchase_id: purchase.id}}, format: :turbo_stream
        }.not_to change(Payment, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end

