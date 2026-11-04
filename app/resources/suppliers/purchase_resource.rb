# frozen_string_literal: true

class Suppliers::PurchaseResource < ApplicationResource
  include ActionView::Helpers::DateHelper

  typelize_from Purchase

  typelize :number
  attribute :amount, &:amount

  typelize :string, nullable: true
  attribute :debt do |purchase|
    format_money(purchase.debt) if purchase.debt.positive?
  end

  typelize :boolean
  attribute :has_debt do |purchase|
    purchase.debt.positive?
  end

  attributes :id

  typelize :string, nullable: true
  attribute :item_price do |purchase|
    format_money(purchase.item_price)
  end

  typelize :string
  attribute :path do |purchase|
    purchase_path(purchase)
  end

  typelize :string
  attribute :purchased_ago do |purchase|
    time_ago_in_words(purchase.date)
  end

  typelize :string
  attribute :title do |purchase|
    purchase_product_title(purchase)
  end

  typelize :string
  attribute :variant do |purchase|
    purchase.variant&.title.to_s
  end
end
