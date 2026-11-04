# frozen_string_literal: true

class VariantAssignmentIssues::AssignmentResource < VariantAssignmentIssues::IssueResource
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
    repair_candidates(product(record)).map do |variant|
      {value: variant.id, label: assignment_label(variant), base_model: variant.base_model?}
    end
  end

  def product(record)
    record.product || record.variant&.product
  end

  def repair_candidates(product)
    return [] unless product

    real, base_models = product.variants.partition { |variant| !variant.base_model? }
    active_real = real.reject(&:deactivated?)
    deactivated_real = real.select(&:deactivated?)
    assignable = active_real.presence || base_models.reject(&:deactivated?)

    (assignable + deactivated_real).sort_by(&:id)
  end
end
