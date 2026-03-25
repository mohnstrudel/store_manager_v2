# frozen_string_literal: true

module Purchases
  class PaymentsController < ApplicationController
    before_action :set_purchase

    def create
      @payment = @purchase.payments.new(payment_params)

      respond_to do |format|
        if @payment.save
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(:payments, partial: "payment/payment")
          end
        else
          format.turbo_stream { head :unprocessable_content }
        end
      end
    end

    private

    def authorize_resourse
      authorize :payment, :create?
    end

    def set_purchase
      @purchase = Purchase.friendly.find(params[:purchase_id])
    end

    def payment_params
      params.expect(payment: [:value])
    end
  end
end
