# frozen_string_literal: true

class BrokenSales::IssueResource < ApplicationResource
  MISSING_PRODUCT = "Missing Product"
  MISSING_VARIANT = "Missing Variant"

  typelize :number
  attribute :id, &:id

  def sentry_event_url(event_id)
    "#{Rails.configuration.x.sentry_organization_url}/issues/?#{{query: event_id}.to_query}" if event_id
  end

  def import_failure_pull_path(failure)
    failure.sale ? sale_pull_path(failure.sale) : broken_sales_import_failure_pull_path(failure)
  end

  def candidate_options(product)
    repair_candidates(product).map do |variant|
      {value: variant.id, label: assignment_label(variant), base_model: variant.base_model?}
    end
  end

  def repair_candidates(product)
    return [] unless product

    real, base_models = product.variants.partition { |variant| !variant.base_model? }
    active_real = real.reject(&:deactivated?)
    deactivated_real = real.select(&:deactivated?)
    assignable = active_real.presence || base_models.reject(&:deactivated?)

    (assignable + deactivated_real).sort_by(&:id)
  end

  def assignment_label(variant)
    (variant.deactivated? && !variant.base_model?) ? "#{variant.title} (Historical)" : variant.title
  end
end
