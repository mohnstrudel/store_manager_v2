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
        render_purchase_show_error
      end
    end

    def update
      if @payment.update(payment_params)
        redirect_to return_path, notice: "Payment was successfully updated", status: :see_other
      else
        render_purchase_show_error
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
      @purchase = Purchase.for_details.friendly.find(params.expect(:purchase_id))
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

    def render_purchase_show_error
      prepare_purchase_show_state
      render inertia: "Purchases/Show", props: helpers.purchase_show_props(
        @purchase,
        purchase_items: @purchase_items,
        payments: @payments,
        new_payment: @new_payment
      ), status: :unprocessable_content
    end
  end
end
