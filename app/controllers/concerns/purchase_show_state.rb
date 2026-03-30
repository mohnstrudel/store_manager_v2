# frozen_string_literal: true

module PurchaseShowState
  extend ActiveSupport::Concern

  private

  def prepare_purchase_show_state
    @purchase_items = @purchase
      .purchase_items
      .for_purchase_details
      .order(updated_at: :desc)
    @payments = payments_for_show
    @new_payment ||= @purchase.payments.new(payment_date: Time.zone.today)
  end

  def payments_for_show
    payments = @purchase.payments.order(payment_date: :asc, created_at: :asc).to_a
    return payments unless inline_payment_errors?

    replace_payment_for_show(payments, @payment)
  end

  def inline_payment_errors?
    defined?(@payment) && @payment&.persisted? && @payment.errors.any?
  end

  def replace_payment_for_show(payments, payment)
    index = payments.index { |existing_payment| existing_payment.id == payment.id }
    return payments unless index

    payments[index] = payment
    payments
  end
end
