# frozen_string_literal: true

module Purchases
  class PaymentsController < ApplicationController
    include PurchaseShowState

    before_action :set_purchase
    before_action :set_payment, only: %i[update destroy]

    def create
      @payment = @purchase.payments.new(payment_params)
      if @payment.save
        redirect_to return_path, notice: "Payment was successfully created", status: :see_other
      else
        @new_payment = @payment
        prepare_purchase_show_state
        render "purchases/show", status: :unprocessable_content
      end
    end

    def update
      if @payment.update(payment_params)
        redirect_to return_path, notice: "Payment was successfully updated", status: :see_other
      else
        prepare_purchase_show_state
        render "purchases/show", status: :unprocessable_content
      end
    end

    def destroy
      @payment.destroy!
      redirect_to return_path, notice: "Payment was successfully removed", status: :see_other
    end

    private

    def authorize_resourse
      authorize :payment, :create?
    end

    def set_purchase
      @purchase = Purchase.for_details.friendly.find(params[:purchase_id])
    end

    def set_payment
      @payment = @purchase.payments.find(params[:id])
    end

    def payment_params
      params.expect(payment: [:value])
    end

    def return_path
      params[:return_to].presence || purchase_path(@purchase)
    end
  end
end
