# frozen_string_literal: true

class VariantAssignmentIssues::IssueResource < ApplicationResource
  MISSING_PRODUCT = "Missing Product"
  MISSING_VARIANT = "Missing Variant"

  typelize :number
  attribute :id, &:id

  def assignment_label(variant)
    (variant.deactivated? && !variant.base_model?) ? "#{variant.title} (Historical)" : variant.title
  end
end
