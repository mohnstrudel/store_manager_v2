# frozen_string_literal: true

class Variant::AssignmentImpact
  CLOSED_STATUSES = [*Sale::CANCELLED_STATUSES, "refunded", "trash"].freeze
  SCOPES = %w[active all closed].freeze
  DEFAULT_SCOPE = "all"
  HISTORY_CONSEQUENCES = {"missing_variant" => :variant_not_recorded, "product_mismatch" => :wrong_variant_recorded}.freeze

  def initialize(integrity:)
    @integrity = integrity
  end

  def order_rows(reason: nil, scope: DEFAULT_SCOPE, product_id: nil)
    rows = lines_in_scope(broken_lines(reason:), scope).order(priority_rank.asc, revenue_column.desc.nulls_last, id_column.desc)
    product_id ? rows.where(product_id:) : rows
  end

  def product_rows(reason: nil)
    order_count = sale_id_column.count(true)

    broken_lines(reason:)
      .joins(:sale)
      .group(:product_id)
      .select(
        :product_id,
        order_count.as("order_count"),
        Arel::Nodes::Count.new([when_status(Sale::ACTIVE_STATUSES, sale_id_column)], true).as("active_order_count"),
        Arel::Nodes::Count.new([when_status(CLOSED_STATUSES, id_column)]).as("closed_line_count"),
        revenue_column.sum.as("revenue")
      )
      .order(order_count.desc, :product_id)
  end

  def consequences(line, reason:, import_failure: nil)
    [
      unreserved_consequence(line),
      ({kind: :debt_miscounted} if line.sale.active? && real_variants?(line)),
      ({kind: HISTORY_CONSEQUENCES.fetch(reason)} if reason),
      ({kind: :not_updating} if import_failure)
    ].compact
  end

  private

  attr_reader :integrity

  def lines_in_scope(lines, scope)
    joined = lines.joins(:sale)

    case scope
    when "active" then joined.merge(Sale.active)
    when "closed" then joined.where(sales: {status: CLOSED_STATUSES})
    else joined
    end
  end

  def broken_lines(reason: nil)
    SaleItem.where(id: integrity.relation_for(:sale_items, reason:).select(:id))
  end

  def priority_rank
    status = Sale.arel_table[:status]

    Arel::Nodes::Case.new
      .when(status.in(Sale::ACTIVE_STATUSES)).then(0)
      .when(status.in(CLOSED_STATUSES)).then(2)
      .else(1)
  end

  def revenue_column
    SaleItem.arel_table[:expected_revenue]
  end

  def id_column
    SaleItem.arel_table[:id]
  end

  def sale_id_column
    SaleItem.arel_table[:sale_id]
  end

  def when_status(statuses, value)
    Arel::Nodes::Case.new.when(Sale.arel_table[:status].in(statuses)).then(value)
  end

  def unreserved_consequence(line)
    units = line.qty.to_i - line.purchase_items_count
    {kind: :units_not_reserved, units:} if line.sale.active? && line.origin_sale_item_id.nil? && units.positive?
  end

  def real_variants?(line)
    product = line.product || line.variant&.product
    product.present? && product.variants.any? { |variant| !variant.base_model? }
  end
end
