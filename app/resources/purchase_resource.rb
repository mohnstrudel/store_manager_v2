# frozen_string_literal: true

class PurchaseResource < ApplicationResource
  typelize_from Purchase

  attributes :id

  typelize :string
  attribute :path do |purchase|
    purchase_path(purchase)
  end

  typelize :string
  attribute :edit_path do |purchase|
    edit_purchase_path(purchase)
  end

  typelize :string
  attribute :product_title do |purchase|
    purchase_product_title(purchase)
  end

  typelize :string, nullable: true
  attribute :product_thumb_url do |purchase|
    thumb = purchase_display_product(purchase)&.media&.min_by(&:position)
    MediaResource.new(thumb).serializable_hash["thumb_url"] if thumb&.image&.attached?
  end

  typelize :string, nullable: true
  attribute :variant_title do |purchase|
    purchase.variant&.title
  end

  attributes :order_reference

  typelize :string
  attribute :supplier_title do |purchase|
    purchase.supplier.title
  end

  typelize :number
  attribute :amount do |purchase|
    purchase.amount.to_i
  end

  typelize "PurchasePaymentProgress"
  attribute :payment_progress do |purchase|
    PurchasePaymentProgressResource.new(purchase).serializable_hash
  end
end
