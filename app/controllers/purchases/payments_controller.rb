# frozen_string_literal: true

module Purchases
  class PaymentsController < ApplicationController
    before_action :set_purchase
    before_action :set_payment, only: %i[update destroy]

    def create
      @payment = @purchase.payments.new(payment_params)
      if @payment.save
        redirect_to return_path, notice: "Payment was successfully created", status: :see_other
      else
        redirect_to failure_path, inertia: inertia_errors(@payment.errors)
      end
    end

    def update
      if @payment.update(payment_params)
        redirect_to return_path, notice: "Payment was successfully updated", status: :see_other
      else
        redirect_to failure_path, inertia: inertia_errors(@payment.errors)
      end
    end

    def destroy
      @payment.destroy!
      redirect_to return_path, notice: "Payment was successfully removed", status: :see_other
    end

    private

    def authorize_resource
      authorize :payment, :create?
    end

    def set_purchase
      @purchase = Purchase.friendly.find(params.expect(:purchase_id))
    end

    def set_payment
      @payment = @purchase.payments.find(params.expect(:id))
    end

    def payment_params
      params.expect(payment: [:value, :payment_date]).tap do |payment|
        payment[:payment_date] = payment[:payment_date].presence || @payment&.payment_date || Time.zone.today
      end
    end

    def return_path
      params[:return_to].presence || purchase_path(@purchase)
    end

    def failure_path
      purchase_path(@purchase)
    end
  end
end
