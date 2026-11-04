# frozen_string_literal: true

class Products::VariantResource < ApplicationResource
  typelize_from Variant

  attributes :id

  typelize :string
  attribute :title, &:title

  typelize :string
  attribute :types_name, &:types_name

  typelize :number
  attribute :weight do |variant|
    variant.weight.to_f
  end

  typelize :number
  attribute :purchase_cost do |variant|
    variant.purchase_cost.to_f
  end

  typelize :number
  attribute :selling_price do |variant|
    variant.selling_price.to_f
  end

  typelize :number, nullable: true
  attribute :selling_price_source_amount do |variant|
    variant.selling_price_source_amount&.to_f
  end

  attributes :selling_price_source_currency

  typelize :boolean
  attribute :deactivated, &:deactivated?

  typelize :number
  attribute :active_sales_count do |variant|
    params.fetch(:sales_sums)[variant.id].to_i
  end

  typelize :number
  attribute :purchases_count do |variant|
    params.fetch(:purchase_sums)[variant.id].to_i
  end

  typelize :string, nullable: true
  attribute :shopify_id_short do |variant|
    variant.shopify_info&.id_short
  end

  typelize :string, nullable: true
  attribute :woo_store_id do |variant|
    variant.woo_info&.store_id
  end

  typelize :string, nullable: true
  attribute :total_purchase_cost do |variant|
    purchase_totals = purchase_totals(variant)
    format_money(purchase_totals[:cost]) if can_view_profitability? && purchase_totals
  end

  typelize :string, nullable: true
  attribute :theoretical_profit do |variant|
    theoretical_profit(variant, purchase_totals(variant)) if can_view_profitability?
  end

  def purchase_totals(variant)
    params.fetch(:purchase_cost_totals)[variant.id]
  end

  def can_view_profitability?
    params[:can_view_profitability] == true
  end

  def theoretical_profit(variant, purchase_totals)
    return if purchase_totals.nil? || purchase_totals[:units].zero?

    selling_price = variant.selling_price.to_d
    return if selling_price.zero?

    average_landed_cost = purchase_totals[:cost] / purchase_totals[:units]
    format_money(selling_price - average_landed_cost - (selling_price * expense_fraction))
  end

  def expense_fraction
    @expense_fraction ||= ExpenseRate.combined_fraction
  end
end
