# frozen_string_literal: true

class BrokenSalesController < ApplicationController
  PER_PAGE = 25
  ISSUE_TYPES = [*Variant::AssignmentIntegrity::ISSUE_TYPES, :import_failures].freeze
  UNFILTERED_ISSUE_TYPES = %i[sale_items import_failures].freeze
  VIEWS = %w[orders products].freeze
  DEFAULT_VIEW = "orders"

  def index
    integrity = Variant::AssignmentIntegrity.new
    impact = Variant::AssignmentImpact.new(integrity:)
    counts = BrokenSales::Counts.new(integrity:).by_tab
    issue_type = selected_issue_type(counts)
    view = selected_view(issue_type)
    filters = issue_filters(integrity, issue_type)
    reason = filters.find { |filter| filter == params[:reason].to_s }
    scope = selected_scope(issue_type)
    product = selected_product(issue_type)
    listed = BrokenSales::Issues.new(integrity:, impact:, issue_type:, view:, reason:, scope:, product_id: product&.id)
    issues = listed.relation.page(params[:page]).per(PER_PAGE)
    records = listed.records(issues)

    render_inertia "BrokenSales/Index", serializer: BrokenSales::IndexResource,
      locals: {
        integrity:,
        impact:,
        counts:,
        issue_type:,
        view:,
        filters:,
        reason:,
        scope:,
        product:,
        issues:,
        records:,
        **listed.lookups(records)
      }
  end

  private

  def selected_issue_type(counts)
    requested = params[:issue_type].presence&.to_sym
    return requested if ISSUE_TYPES.include?(requested)

    counts[:sale_items].positive? ? :sale_items : :purchases
  end

  def selected_view(issue_type)
    return unless issue_type == :sale_items

    VIEWS.include?(params[:view]) ? params[:view] : DEFAULT_VIEW
  end

  def issue_filters(integrity, issue_type)
    UNFILTERED_ISSUE_TYPES.include?(issue_type) ? [] : integrity.reasons_for(issue_type)
  end

  def selected_scope(issue_type)
    return unless issue_type == :sale_items

    requested = params[:scope].to_s
    Variant::AssignmentImpact::SCOPES.include?(requested) ? requested : Variant::AssignmentImpact::DEFAULT_SCOPE
  end

  def selected_product(issue_type)
    Product.find_by(id: params[:product_id].presence) if issue_type == :sale_items
  end

  def authorize_resource
    authorize :broken_sale, :index?
  end
end
