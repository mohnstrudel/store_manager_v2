# frozen_string_literal: true

class Products::SoldItemResource < ApplicationResource
  typelize_from SaleItem

  attributes :id

  typelize :string
  attribute :sale_path do |sale_item|
    sale_path(sale_item.sale)
  end

  typelize '"shopify" | "woo" | null'
  attribute :store_type do |sale_item|
    store_reference(sale_item.sale).first
  end

  typelize :string
  attribute :store_id do |sale_item|
    store_reference(sale_item.sale).last.presence || ""
  end

  typelize :string, nullable: true
  attribute :customer_name do |sale_item|
    sale_item.sale.customer.full_name
  end

  typelize :string, nullable: true
  attribute :customer_email do |sale_item|
    sale_item.sale.customer.email
  end

  typelize :string
  attribute :date do |sale_item|
    format_date(sale_item.sale.woo_created_at.presence || sale_item.created_at)
  end

  typelize :string, nullable: true
  attribute :variant_title do |sale_item|
    sale_item.variant&.title if params[:has_variants]
  end

  attributes :qty

  typelize :string, nullable: true
  attribute :status do |sale_item|
    sale_item.sale.status
  end

  typelize :string
  attribute :warehouse do |sale_item|
    sale_item.purchase_items.first&.warehouse&.name.presence || ""
  end

  typelize :string, nullable: true
  attribute :purchase_item_path do |sale_item|
    purchase_item = sale_item.purchase_items.first
    purchase_item_path(purchase_item) if purchase_item
  end

  def store_reference(sale)
    if sale.shopify_info&.store_id.present?
      ["shopify", sale.shopify_info.id_short]
    elsif sale.woo_info&.store_id.present?
      ["woo", sale.woo_info.store_id]
    else
      [nil, sale.shopify_name.presence || sale.woo_store_id]
    end
  end
end
