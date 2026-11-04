# frozen_string_literal: true

class Dashboard::UnpaidPurchaseResource < ApplicationResource
  include ActionView::Helpers::DateHelper

  typelize_from Purchase

  attributes :id

  typelize :string
  attribute :path do |purchase|
    purchase_path(purchase)
  end

  typelize :string
  attribute :purchased_ago do |purchase|
    time_ago_in_words(purchase.created_at)
  end

  typelize :string, nullable: true
  attribute :supplier_title do |purchase|
    purchase.supplier.title
  end

  typelize :string, nullable: true
  attribute :item_price do |purchase|
    format_money(purchase.item_price)
  end

  typelize :number
  attribute :amount do |purchase|
    purchase.amount.to_i
  end
end
