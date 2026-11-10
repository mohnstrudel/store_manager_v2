# frozen_string_literal: true

class BrokenSales::Issues
  VARIANT_OPTIONS = %i[color size version].freeze
  private_constant :VARIANT_OPTIONS

  def initialize(integrity:, impact:, issue_type:, view:, reason:, scope:, product_id:)
    @integrity = integrity
    @impact = impact
    @issue_type = issue_type
    @view = view
    @reason = reason
    @scope = scope
    @product_id = product_id
  end

  def relation
    return impact.product_rows(reason:) if products_view?
    return Sale::ImportFailure.unresolved.order(last_failed_at: :desc, id: :desc) if issue_type == :import_failures
    return impact.order_rows(reason:, scope:, product_id:) if issue_type == :sale_items

    integrity.relation_for(issue_type, reason:).order(updated_at: :desc, id: :desc)
  end

  def records(page)
    return page.preload(product: {variants: VARIANT_OPTIONS}).to_a if products_view?

    case issue_type
    when :import_failures
      page.preload(sale: :woo_info).to_a
    when :purchases
      page.includes(
        :purchase_items,
        variant: [*VARIANT_OPTIONS, {product: {variants: VARIANT_OPTIONS}}],
        product: {variants: VARIANT_OPTIONS}
      ).to_a
    when :sale_items
      page.preload(
        sale: %i[customer woo_info],
        variant: [*VARIANT_OPTIONS, {product: {variants: VARIANT_OPTIONS}}],
        product: {variants: VARIANT_OPTIONS}
      ).to_a
    when :purchase_item_links
      page.includes(
        purchase: [:product, {variant: VARIANT_OPTIONS}],
        sale_item: [:product, :sale, {variant: VARIANT_OPTIONS}]
      ).to_a
    when :sku_collisions
      page.includes(:product, *VARIANT_OPTIONS).to_a
    when :shopify_conflicts
      page.includes(:product, conflicting_variant: VARIANT_OPTIONS).to_a
    end
  end

  def lookups(records)
    {
      reasons: reasons(records),
      siblings_by_sku: siblings_by_sku(records),
      import_failures_by_sale_id: import_failures_by_sale_id(records),
      replacements_by_identity: replacements_by_identity(records)
    }
  end

  private

  attr_reader :integrity, :impact, :issue_type, :view, :reason, :scope, :product_id

  def products_view?
    view == "products"
  end

  def reasons(records)
    return {} if products_view? || issue_type == :import_failures

    integrity.reasons_by_id(issue_type, records.map(&:id))
  end

  def siblings_by_sku(records)
    return {} unless issue_type == :sku_collisions

    integrity.duplicate_sku_variants.where(sku: records.map(&:sku)).includes(:product, *VARIANT_OPTIONS).group_by(&:sku)
  end

  def import_failures_by_sale_id(records)
    return {} unless view == "orders"

    sales = records.to_h { |record| [record.sale_id, record.sale] }
    Sale::ImportFailure.unresolved.where(sale_id: sales.keys).index_by(&:sale_id).each_value do |failure|
      failure.sale = sales.fetch(failure.sale_id)
    end
  end

  def replacements_by_identity(records)
    return {} unless issue_type == :purchase_item_links

    identities = records.map { |purchase_item| [purchase_item.sale_item.product_id, purchase_item.sale_item.variant_id] }.uniq
    PurchaseItem.unlinked_ids_by_identity(identities)
  end
end
