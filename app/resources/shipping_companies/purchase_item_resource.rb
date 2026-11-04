# frozen_string_literal: true

class ShippingCompanies::PurchaseItemResource < ApplicationResource
  include ActionView::Helpers::DateHelper

  typelize_from PurchaseItem

  attributes :id

  typelize :string
  attribute :path do |purchase_item|
    purchase_item_path(purchase_item)
  end

  typelize :string, nullable: true
  attribute :product_full_title do |purchase_item|
    purchase_item.product.full_title
  end

  typelize :string
  attribute :purchased_ago do |purchase_item|
    time_ago_in_words(purchase_item.purchase&.date || purchase_item.created_at)
  end

  attributes :tracking_number
end
