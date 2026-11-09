# frozen_string_literal: true

class SalePaymentPlanResource < ApplicationResource
  typelize_from SalePaymentPlan

  attributes :id

  typelize '"deposit" | "installments" | "payment_terms"'
  attribute :kind, &:kind

  attributes :expected_parts

  typelize :number
  attribute :collected_parts, &:collected_parts

  typelize :number, nullable: true
  attribute :sale_part_number do |plan|
    plan.part_number_for(sale)
  end

  typelize :boolean
  attribute :is_origin_sale do |plan|
    plan.origin_sale_id == sale.id
  end

  typelize :number, nullable: true
  attribute :deposit_percent do |plan|
    compact_number(plan.deposit_percent)
  end

  typelize :string, nullable: true
  attribute :projected_total do |plan|
    format_money(plan.projected_total)
  end

  typelize :string, nullable: true
  attribute :projected_collected do |plan|
    format_money(plan.projected_total - plan.projected_remainder) unless plan.projected_total.nil?
  end

  typelize({path: :string, identifier: :string}, nullable: true)
  attribute :origin_sale do |plan|
    origin = plan.origin_sale
    sale_reference(origin) unless origin.nil? || origin.id == sale.id
  end

  typelize "Array<{ sequence: number; path: string; identifier: string; is_current_sale: boolean }>"
  attribute :payments do |plan|
    plan.linked_parts.map do |part|
      {sequence: part.sequence, **sale_reference(part.sale), is_current_sale: part.sale_id == sale.id}
    end
  end

  def sale
    params.fetch(:sale)
  end

  def compact_number(value)
    return if value.nil?

    value.to_d.frac.zero? ? value.to_i : value.to_f
  end

  def sale_reference(referenced_sale)
    {path: sale_path(referenced_sale), identifier: referenced_sale.shop_identifier.presence || referenced_sale.id.to_s}
  end
end
