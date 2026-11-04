# frozen_string_literal: true

class Warehouses::PurchaseItemResource < ApplicationResource
  include ApplicationHelper

  typelize_from PurchaseItem

  attributes :id

  typelize :string
  attribute :path do |purchase_item|
    purchase_item_path(purchase_item)
  end

  typelize :string
  attribute :title do |purchase_item|
    purchase_product_title(purchase_item.purchase)
  end

  typelize :string, nullable: true
  attribute :variant_title do |purchase_item|
    purchase_item.purchase.variant&.title
  end

  typelize :string, nullable: true
  attribute :sku do |purchase_item|
    purchase_item.purchase.variant&.sku || purchase_display_product(purchase_item.purchase)&.base_variant&.sku
  end

  typelize :string, nullable: true
  attribute :sale_path do |purchase_item|
    sale_path(purchase_item.sale) if purchase_item.sale
  end

  typelize :string, nullable: true
  attribute :sale_title do |purchase_item|
    purchase_item.sale&.title
  end

  typelize '"shopify" | "woo" | null'
  attribute :sale_store_type do |purchase_item|
    sale_store_type(purchase_item.sale)
  end

  typelize :string
  attribute :sale_summary do |purchase_item|
    purchase_item.sale ? sale_summary(purchase_item.sale) : ""
  end

  typelize :string, nullable: true
  attribute :sale_note do |purchase_item|
    purchase_item.sale&.note
  end

  typelize :string, nullable: true
  attribute :customer_email do |purchase_item|
    purchase_item.sale&.customer&.email
  end

  typelize :string
  attribute :tracking_number do |purchase_item|
    purchase_item.tracking_number.to_s
  end

  typelize :string
  attribute :shipping_company_name do |purchase_item|
    purchase_item.shipping_company&.name.to_s
  end

  attributes :shipping_company_id

  typelize "PurchasePaymentProgress"
  attribute :payment_progress do |purchase_item|
    PurchasePaymentProgressResource.new(purchase_item.purchase).serializable_hash
  end

  def sale_store_type(sale)
    return nil unless sale
    return "shopify" if sale.shopify_name.present? || sale.shopify_id.present?

    "woo" if sale.woo_store_id.present?
  end

  def sale_summary(sale)
    address = sale.shipping_address

    [
      sale.customer.full_name,
      address&.address_1,
      address&.address_2,
      address&.postcode,
      address&.city,
      address&.country,
      address&.phone.presence || sale.customer.phone
    ].compact_blank.join(", ")
  end
end
