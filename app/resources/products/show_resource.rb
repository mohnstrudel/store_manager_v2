# frozen_string_literal: true

class Products::ShowResource < ApplicationResource
  PROFITABILITY_AMOUNTS = %i[
    potential_sales expected_total_cost business_expenses expected_net_profit collected_revenue purchase_paid cash_position
  ].freeze

  typelize "ProductsDetail"
  attribute :product do |page|
    Products::DetailResource.new(page.fetch(:product), params: {can_pull_from_shopify: page.fetch(:can_pull_from_shopify)}).serializable_hash
  end

  typelize "Array<ProductsVariant>"
  attribute :variants do |page|
    product = page.fetch(:product)

    Products::VariantResource.new(
      product.variants,
      params: {
        sales_sums: product.variant_sales_sums,
        purchase_sums: product.variant_purchase_sums,
        purchase_cost_totals: product.variant_purchase_cost_totals,
        can_view_profitability: page.fetch(:can_view_profitability)
      }
    ).serializable_hash
  end

  typelize "Array<ProductsSaleItem>"
  attribute :active_sales do |page|
    sale_items(page, page.fetch(:product).active_sale_items)
  end

  typelize "Array<ProductsPaymentItem>"
  attribute :active_payments do |page|
    payment_items(page, page.fetch(:product).active_payment_items)
  end

  typelize "Array<ProductsSaleItem>"
  attribute :completed_sales do |page|
    sale_items(page, page.fetch(:product).completed_sale_items)
  end

  typelize "Array<ProductsPaymentItem>"
  attribute :completed_payments do |page|
    payment_items(page, page.fetch(:product).completed_payment_items)
  end

  typelize "Array<ProductsPurchase>"
  attribute :purchases do |page|
    Products::PurchaseResource.new(page.fetch(:purchases)).serializable_hash
  end

  typelize({
    potential_sales: "string | null",
    expected_total_cost: "string | null",
    business_expenses: "string | null",
    expected_net_profit: "string | null",
    collected_revenue: "string | null",
    purchase_paid: "string | null",
    cash_position: "string | null"
  }, nullable: true)
  attribute :profitability do |page|
    profitability(page.fetch(:product)) if page.fetch(:can_view_profitability)
  end

  def sale_items(page, sale_items)
    Products::SaleItemResource.new(sale_items, params: {has_variants: page.fetch(:product).variants.any?}).serializable_hash
  end

  def payment_items(page, sale_items)
    Products::PaymentItemResource.new(sale_items, params: {has_variants: page.fetch(:product).variants.any?}).serializable_hash
  end

  def profitability(product)
    summary = product.profitability(expense_fraction: ExpenseRate.combined_fraction)

    PROFITABILITY_AMOUNTS.index_with { |amount| format_money(summary[amount]) }
  end
end
