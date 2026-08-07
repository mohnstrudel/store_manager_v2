# frozen_string_literal: true

class Variant::AssignmentIntegrity
  ISSUE_TYPES = %i[purchases sale_items purchase_item_links].freeze

  ASSIGNMENT_REASONS = {
    "missing_product" => "%<table>s.product_id IS NULL",
    "missing_variant" => "%<table>s.variant_id IS NULL OR variants.id IS NULL",
    "product_mismatch" => <<~SQL.squish
      %<table>s.product_id IS NOT NULL
      AND %<table>s.variant_id IS NOT NULL
      AND variants.id IS NOT NULL
      AND variants.product_id IS DISTINCT FROM %<table>s.product_id
    SQL
  }.freeze

  LINK_REASONS = {
    "purchase_identity" => <<~SQL.squish,
      purchases.id IS NULL
      OR purchase_items.product_id IS DISTINCT FROM purchases.product_id
      OR purchase_items.variant_id IS DISTINCT FROM purchases.variant_id
    SQL
    "sale_item_identity" => <<~SQL.squish
      sale_items.id IS NULL
      OR purchase_items.product_id IS DISTINCT FROM sale_items.product_id
      OR purchase_items.variant_id IS DISTINCT FROM sale_items.variant_id
    SQL
  }.freeze

  def counts
    {
      purchases: broken_purchases.count,
      sale_items: broken_sale_items.count,
      purchase_item_links: incompatible_purchase_item_links.count
    }
  end

  def relation_for(issue_type, reason: nil)
    type = issue_type.to_sym
    raise ArgumentError, "Unknown Variant assignment issue type: #{issue_type}" unless ISSUE_TYPES.include?(type)

    relation = public_send(relation_name_for(type))
    return relation if reason.blank?

    case type
    when :purchases
      filter_assignment_relation(relation, table: "purchases", reason:)
    when :sale_items
      filter_assignment_relation(relation, table: "sale_items", reason:)
    when :purchase_item_links
      filter_link_relation(relation, reason:)
    end
  end

  def broken_purchases
    assignment_relation(Purchase, table: "purchases")
  end

  def broken_sale_items
    assignment_relation(SaleItem, table: "sale_items")
  end

  def incompatible_purchase_item_links
    PurchaseItem
      .where.not(sale_item_id: nil)
      .left_joins(:purchase, :sale_item)
      .where(link_predicate)
      .distinct
  end

  def purchase_item_purchase_identity_mismatches
    PurchaseItem
      .left_joins(:purchase)
      .where(LINK_REASONS.fetch("purchase_identity"))
      .distinct
  end

  def broken_purchase?(purchase_or_id)
    broken_purchases.exists?(id: record_id(purchase_or_id))
  end

  def broken_sale_item?(sale_item_or_id)
    broken_sale_items.exists?(id: record_id(sale_item_or_id))
  end

  def incompatible_purchase_item_link?(purchase_item_or_id)
    incompatible_purchase_item_links.exists?(id: record_id(purchase_item_or_id))
  end

  def purchase_item_purchase_identity_mismatch?(purchase_item_or_id)
    purchase_item_purchase_identity_mismatches.exists?(id: record_id(purchase_item_or_id))
  end

  def reasons_for(issue_type)
    (issue_type.to_sym == :purchase_item_links) ? LINK_REASONS.keys : ASSIGNMENT_REASONS.keys
  end

  def reason_for(issue_type, record_or_id)
    record_id = record_id(record_or_id)
    reasons_for(issue_type).find do |reason|
      relation_for(issue_type, reason:).exists?(id: record_id)
    end
  end

  private

  def assignment_relation(model, table:)
    model.left_joins(:variant).where(assignment_predicate(table:)).distinct
  end

  def assignment_predicate(table:)
    ASSIGNMENT_REASONS.values
      .map { |predicate| "(#{format(predicate, table:)})" }
      .join(" OR ")
  end

  def link_predicate
    LINK_REASONS.values.map { |predicate| "(#{predicate})" }.join(" OR ")
  end

  def filter_assignment_relation(relation, table:, reason:)
    predicate = ASSIGNMENT_REASONS[reason.to_s]
    predicate ? relation.where(format(predicate, table:)) : relation.none
  end

  def filter_link_relation(relation, reason:)
    predicate = LINK_REASONS[reason.to_s]
    predicate ? relation.where(predicate) : relation.none
  end

  def relation_name_for(issue_type)
    {
      purchases: :broken_purchases,
      sale_items: :broken_sale_items,
      purchase_item_links: :incompatible_purchase_item_links
    }.fetch(issue_type)
  end

  def record_id(record_or_id)
    record_or_id.respond_to?(:id) ? record_or_id.id : record_or_id
  end
end
