# frozen_string_literal: true

class PurchaseItems::ListingResource < ApplicationResource
  include ApplicationHelper

  typelize_from PurchaseItem

  attributes :id

  typelize :string
  attribute :path do |purchase_item|
    purchase_item_path(purchase_item)
  end

  typelize :string
  attribute :edit_path do |purchase_item|
    edit_purchase_item_path(purchase_item)
  end

  typelize :string
  attribute :purchase_path do |purchase_item|
    purchase_path(purchase_item.purchase)
  end

  typelize :string
  attribute :purchase_title do |purchase_item|
    purchase_item.purchase.full_title
  end

  typelize :string, nullable: true
  attribute :product_path do |purchase_item|
    purchase_product_path(purchase_item.purchase)
  end

  typelize :string
  attribute :product_title do |purchase_item|
    purchase_product_title(purchase_item.purchase)
  end

  typelize :string, nullable: true
  attribute :variant_title do |purchase_item|
    purchase_item.purchase.variant_title
  end

  typelize :string
  attribute :warehouse_name do |purchase_item|
    purchase_item.warehouse.name
  end

  typelize :string
  attribute :warehouse_path do |purchase_item|
    warehouse_path(purchase_item.warehouse)
  end

  typelize :string, nullable: true
  attribute :sale_path do |purchase_item|
    sale_path(purchase_item.sale) if purchase_item.sale
  end

  typelize :string, nullable: true
  attribute :sale_title do |purchase_item|
    purchase_item.sale&.full_title
  end

  typelize :string, nullable: true
  attribute :customer_email do |purchase_item|
    purchase_item.customer&.email
  end

  typelize :string, nullable: true
  attribute :tracking_number do |purchase_item|
    safe_blank_render(purchase_item.tracking_number)
  end

  typelize :string, nullable: true
  attribute :shipping_company_name do |purchase_item|
    safe_blank_render(purchase_item.shipping_company&.name)
  end

  typelize :string, nullable: true
  attribute :shipping_cost do |purchase_item|
    format_money(purchase_item.shipping_cost)
  end

  typelize :string
  attribute :updated_at do |purchase_item|
    format_date(purchase_item.updated_at)
  end
end
