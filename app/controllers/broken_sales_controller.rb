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
    issue_type = selected_issue_type(integrity)
    view = selected_view(issue_type)
    filters = issue_filters(integrity, issue_type)
    reason = filters.find { |filter| filter == params[:reason].to_s }
    scope = selected_scope(issue_type)
    product = selected_product(issue_type)
    issues = issue_relation(integrity, impact, issue_type, view:, reason:, scope:, product_id: product&.id)
      .page(params[:page])
      .per(PER_PAGE)
    records = issue_records(issue_type, view, issues)

    render_inertia "BrokenSales/Index", serializer: BrokenSales::IndexResource,
      locals: {
        integrity:,
        impact:,
        counts: BrokenSales::Counts.new(integrity:).by_tab,
        issue_type:,
        view:,
        filters:,
        reason:,
        scope:,
        product:,
        issues:,
        records:,
        reasons: row_reasons(integrity, issue_type, view, records),
        siblings_by_sku: siblings_by_sku(integrity, issue_type),
        import_failures_by_sale_id: import_failures_by_sale_id(view, records)
      }
  end

  private

  def selected_issue_type(integrity)
    requested = params[:issue_type].presence&.to_sym
    return requested if ISSUE_TYPES.include?(requested)

    integrity.broken_sale_items.exists? ? :sale_items : :purchases
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

  def issue_relation(integrity, impact, issue_type, view:, reason:, scope:, product_id:)
    return impact.product_rows(reason:) if view == "products"
    return Sale::ImportFailure.unresolved.order(last_failed_at: :desc, id: :desc) if issue_type == :import_failures
    return impact.order_rows(reason:, scope:, product_id:) if issue_type == :sale_items

    integrity.relation_for(issue_type, reason:).order(updated_at: :desc, id: :desc)
  end

  def issue_records(issue_type, view, issues)
    return issues.preload(product: {variants: %i[color size version]}).to_a if view == "products"

    case issue_type
    when :import_failures
      issues.preload(sale: :woo_info).to_a
    when :purchases
      issues.includes(
        :purchase_items,
        variant: [:color, :size, :version, {product: {variants: %i[color size version]}}],
        product: {variants: %i[color size version]}
      ).to_a
    when :sale_items
      issues.preload(
        sale: %i[customer woo_info],
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

  def row_reasons(integrity, issue_type, view, records)
    return {} if view == "products" || issue_type == :import_failures

    integrity.reasons_by_id(issue_type, records.map(&:id))
  end

  def siblings_by_sku(integrity, issue_type)
    return {} unless issue_type == :sku_collisions

    integrity.duplicate_sku_variants.includes(:product, :color, :size, :version).group_by(&:sku)
  end

  def import_failures_by_sale_id(view, records)
    return {} unless view == "orders"

    Sale::ImportFailure.unresolved.includes(:sale).where(sale_id: records.map(&:sale_id)).index_by(&:sale_id)
  end

  def authorize_resource
    authorize :broken_sale, :index?
  end
end
