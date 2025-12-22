# frozen_string_literal: true
class PaymentsController < ApplicationController
  def create
    @payment = Payment.create(payment_params)

    respond_to do |format|
      if @payment.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(:payments, partial: "payment/payment")
        end
      end
    end
  end

  private

  def payment_params
    params
      .fetch(:payment, {})
      .permit(
        :value,
        :purchase_id
      )
  end
end
