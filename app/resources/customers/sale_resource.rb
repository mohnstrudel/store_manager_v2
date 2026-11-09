# frozen_string_literal: true

class Customers::SaleResource < SaleSettlementResource
  typelize_from Sale

  attributes :id

  typelize :string
  attribute :path do |sale|
    sale_path(sale)
  end

  typelize :string, nullable: true
  attribute :store_id do |sale|
    if sale.shopify_info&.store_id.present?
      sale.shopify_info.id_short
    elsif sale.woo_info&.store_id.present?
      sale.woo_info.store_id
    else
      sale.shopify_name.presence || sale.woo_store_id
    end
  end

  typelize :string
  attribute :sale_identifier do |sale|
    sale.shop_identifier.presence || sale.id.to_s
  end

  typelize :string
  attribute :sold_product_name do |sale|
    titles = sale.sale_items.map(&:title).compact_blank

    if titles.size > 1
      "#{titles.first} + #{titles.size - 1} more"
    else
      titles.first.to_s
    end
  end

  typelize :string, nullable: true
  attribute :product_thumb_url do |sale|
    product = sale.sale_items.first&.product
    thumb_url(product) if product
  end

  typelize '"shopify" | "woo"', nullable: true
  attribute :store_type do |sale|
    if sale.shopify_info&.store_id.present? || sale.shopify_name.present? || sale.shopify_id.present?
      "shopify"
    elsif sale.woo_info&.store_id.present?
      "woo"
    end
  end

  typelize "Array<{ name: string; path: string }>"
  attribute :warehouses do |sale|
    sale.sale_items.flat_map(&:purchase_items).map(&:warehouse).uniq.map do |warehouse|
      {name: warehouse.name, path: warehouse_path(warehouse)}
    end
  end

  typelize :string, nullable: true
  attribute :total do |sale|
    format_money(sale.total)
  end

  typelize :string, nullable: true
  attribute :country do |sale|
    sale.shipping_address&.country
  end

  typelize :string, nullable: true
  attribute :city do |sale|
    sale.shipping_address&.city
  end

  attributes :note

  typelize :string
  attribute :created_at do |sale|
    format_date(sale.shop_created_at.presence || sale.created_at)
  end

  typelize :string
  attribute :updated_at do |sale|
    format_date(sale.shop_updated_at.presence || sale.updated_at)
  end

  typelize :boolean
  attribute :is_follow_up_payment, &:follow_up_payment?

  typelize :boolean
  attribute :partially_paid do |sale|
    sale.payment_plans.empty? && sale.partially_paid?
  end

  typelize "Array<SalePaymentPlan>"
  attribute :payment_plans do |sale|
    SalePaymentPlanResource.new(sale.payment_plans, params: {sale:}).serializable_hash
  end
end
