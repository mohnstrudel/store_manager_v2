# frozen_string_literal: true

class VariantAssignmentIssuesController < ApplicationController
  PER_PAGE = 25

  def index
    integrity = Variant::AssignmentIntegrity.new
    issue_type = selected_issue_type
    reason = selected_reason(integrity, issue_type)
    issues = integrity
      .relation_for(issue_type, reason:)
      .order(updated_at: :desc, id: :desc)
      .page(params[:page])
      .per(PER_PAGE)
    records = issue_records(issue_type, issues)

    render_inertia "VariantAssignmentIssues/Index", serializer: VariantAssignmentIssues::IndexResource,
      locals: {
        integrity:,
        issue_type:,
        reason:,
        issues:,
        records:,
        reasons: integrity.reasons_by_id(issue_type, records.map(&:id)),
        siblings_by_sku: siblings_by_sku(integrity, issue_type)
      }
  end

  private

  def selected_issue_type
    requested = params[:issue_type].presence&.to_sym
    Variant::AssignmentIntegrity::ISSUE_TYPES.include?(requested) ? requested : :purchases
  end

  def selected_reason(integrity, issue_type)
    requested = params[:reason].to_s
    integrity.reasons_for(issue_type).include?(requested) ? requested : nil
  end

  def issue_records(issue_type, issues)
    case issue_type
    when :purchases
      issues.includes(
        :purchase_items,
        variant: [:color, :size, :version, {product: {variants: %i[color size version]}}],
        product: {variants: %i[color size version]}
      ).to_a
    when :sale_items
      issues.includes(
        :purchase_items,
        :sale,
        variant: [:color, :size, :version, {product: {variants: %i[color size version]}}],
        product: {variants: %i[color size version]}
      ).to_a
    when :purchase_item_links
      issues.includes(
        purchase: [:product, {variant: %i[color size version]}],
        sale_item: [:product, :sale, {variant: %i[color size version]}]
      ).to_a
    when :sku_collisions
      issues.includes(:product, :color, :size, :version).to_a
    when :shopify_conflicts
      issues.includes(:product, conflicting_variant: %i[color size version]).to_a
    end
  end

  def siblings_by_sku(integrity, issue_type)
    return {} unless issue_type == :sku_collisions

    integrity.duplicate_sku_variants.includes(:product, :color, :size, :version).group_by(&:sku)
  end

  def authorize_resource
    authorize :variant_assignment_issue, :index?
  end
end
