# frozen_string_literal: true

class Purchases::PaymentResource < ApplicationResource
  typelize_from Payment

  attributes :id

  typelize :string
  attribute :update_path do |payment|
    purchase_payment_path(params.fetch(:purchase), payment)
  end

  typelize :string
  attribute :destroy_path do |payment|
    purchase = params.fetch(:purchase)
    purchase_payment_path(purchase, payment, return_to: purchase_path(purchase))
  end

  typelize :string
  attribute :payment_date do |payment|
    payment.payment_date.to_date.iso8601
  end

  typelize :string
  attribute :value do |payment|
    decimal_field_value(payment.value)
  end
end
