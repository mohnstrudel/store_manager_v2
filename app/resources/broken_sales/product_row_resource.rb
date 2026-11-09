# frozen_string_literal: true

class BrokenSales::ProductRowResource < BrokenSales::IssueResource
  typelize '"product"'
  attribute :kind do |_row|
    "product"
  end

  typelize :number
  attribute :id, &:product_id

  typelize :string
  attribute :product_title do |row|
    row.product.full_title
  end

  typelize :number
  attribute :order_count, &:order_count

  typelize :number
  attribute :active_order_count, &:active_order_count

  typelize :number
  attribute :closed_line_count, &:closed_line_count

  typelize :string, nullable: true
  attribute :revenue do |row|
    format_usd(row.revenue)
  end

  typelize "Array<VariantAssignmentOption>"
  attribute :candidates do |row|
    candidate_options(row.product)
  end
end
