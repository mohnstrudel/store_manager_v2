# frozen_string_literal: true

class BrokenSales::AssignmentResource < BrokenSales::IssueResource
  typelize :string
  attribute :reason do |record|
    params.fetch(:reasons)[record.id]
  end

  typelize :number, nullable: true
  attribute :product_id, &:product_id

  typelize :string
  attribute :product_title do |record|
    product(record)&.full_title || MISSING_PRODUCT
  end

  typelize :number, nullable: true
  attribute :variant_id, &:variant_id

  typelize :string
  attribute :current_variant_label do |record|
    record.variant ? assignment_label(record.variant) : MISSING_VARIANT
  end

  typelize :number, nullable: true
  attribute :current_variant_product_id do |record|
    record.variant&.product_id
  end

  typelize "Array<VariantAssignmentOption>"
  attribute :candidates do |record|
    candidate_options(product(record))
  end

  def product(record)
    record.product || record.variant&.product
  end
end
