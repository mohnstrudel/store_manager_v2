# frozen_string_literal: true

class SaleResource < SaleSettlementResource
  typelize_from Sale

  attributes :id

  typelize :string
  attribute :path do |sale|
    sale_path(sale)
  end

  attributes :status

  typelize :boolean
  attribute :active, &:active?

  typelize :boolean
  attribute :completed, &:completed?

  typelize :string, nullable: true
  attribute :total do |sale|
    format_money(sale.total)
  end

  typelize :string
  attribute :created_at do |sale|
    format_date(sale.shop_created_at.presence || sale.created_at)
  end

  typelize :string
  attribute :updated_at do |sale|
    format_date(sale.shop_updated_at.presence || sale.updated_at)
  end

  attributes :shopify_name, :shopify_id

  typelize :string, nullable: true
  attribute :shopify_id_short do |sale|
    sale.shopify_info&.id_short
  end

  typelize :string, nullable: true
  attribute :woo_store_id, &:woo_store_id

  typelize :string, nullable: true
  attribute :shop_identifier, &:shop_identifier

  typelize :boolean
  attribute :is_follow_up_payment, &:follow_up_payment?

  typelize "Array<SalesTag>"
  attribute :tags do |sale|
    SalesTagResource.new(sale.sales_tags.sort_by(&:sort_key)).serializable_hash
  end
end
