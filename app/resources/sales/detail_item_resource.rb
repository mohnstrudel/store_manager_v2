# frozen_string_literal: true

class Sales::DetailItemResource < ApplicationResource
  typelize_from SaleItem

  attributes :id

  typelize :string
  attribute :title, &:title

  attributes :qty

  typelize :string
  attribute :product_path do |item|
    product_path(item.product)
  end

  typelize :string, nullable: true
  attribute :product_thumb_url do |item|
    thumb_url(item.product)
  end

  typelize :boolean
  attribute :shopify_variant_unlinked, &:shopify_variant_unlinked?

  many :purchase_items, resource: Sales::DetailPurchaseItemResource

  typelize :string, nullable: true
  attribute :price do |item|
    format_money(params[:origin_price] || item.expected_revenue.to_d + params.fetch(:shipping_shares).fetch(item.id, 0))
  end

  typelize({expected_revenue: "string | null", purchase_cost: "string | null", expected_final_profit: "string | null"}, nullable: true)
  attribute :profitability do |item|
    if params[:can_view_profitability]
      {
        expected_revenue: format_money(item.expected_revenue),
        purchase_cost: format_money(item.purchase_cost),
        expected_final_profit: format_money(item.expected_final_profit(params.fetch(:expense_fraction)))
      }
    end
  end
end
