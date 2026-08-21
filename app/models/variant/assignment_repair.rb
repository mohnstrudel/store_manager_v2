# frozen_string_literal: true

class Variant::AssignmentRepair
  InvalidCandidate = Class.new(StandardError)
  ShopifyIdentityReconciliation = Data.define(
    :removed_store_info_count,
    :repaired_purchase_count,
    :repaired_sale_item_count
  )

  class << self
    def repair_purchase!(purchase_id:, variant_id:)
      new.repair_purchase!(purchase_id:, variant_id:)
    end

    def repair_sale_item!(sale_item_id:, variant_id:, product_id: nil)
      new.repair_sale_item!(sale_item_id:, variant_id:, product_id:)
    end

    def repair_purchase_item_link!(purchase_item_id:)
      new.repair_purchase_item_link!(purchase_item_id:)
    end

    def repair_purchase_item_identity!(purchase_item_id:)
      new.repair_purchase_item_identity!(purchase_item_id:)
    end

    def reconcile_duplicate_shopify_identity!(store_id:, canonical_store_info_id:)
      new.reconcile_duplicate_shopify_identity!(
        store_id:,
        canonical_store_info_id:
      )
    end
  end

  def initialize(integrity: Variant::AssignmentIntegrity.new)
    @integrity = integrity
  end

  def repair_purchase!(purchase_id:, variant_id:)
    Purchase.transaction do
      purchase = Purchase.lock.find(purchase_id)
      return :noop unless integrity.broken_purchase?(purchase.id)

      product, variant = lock_repair_candidate!(purchase, variant_id)
      sale_items = lock_relevant_sale_items(
        source_ids: purchase.purchase_items.where.not(sale_item_id: nil).pluck(:sale_item_id),
        target_relation: fillable_sale_items(product_id: product.id, variant_id: variant.id)
      )
      purchase_items = lock_relevant_purchase_items(
        required_ids: purchase.purchase_items.ids,
        sale_items:
      )
      return :noop unless integrity.broken_purchase?(purchase.id)
      ensure_source_sale_items_locked!(purchase_items, sale_items)

      # Historical repair must bypass normal assignability callbacks and notifications.
      purchase.update_columns( # rubocop:disable Rails/SkipsModelValidations
        product_id: product.id,
        variant_id: variant.id,
        updated_at: Time.current
      ) # rubocop:enable Rails/SkipsModelValidations
      purchase_items
        .select { |purchase_item| purchase_item.purchase_id == purchase.id }
        .each do |purchase_item|
          # PurchaseItem identity is derived and already protected by the locked command.
          purchase_item.update_columns( # rubocop:disable Rails/SkipsModelValidations
            product_id: product.id,
            variant_id: variant.id,
            updated_at: Time.current
          ) # rubocop:enable Rails/SkipsModelValidations
        end

      reconcile_locked_links!(sale_items:, purchase_items:)
      :repaired
    end
  end

  def repair_sale_item!(sale_item_id:, variant_id:, product_id: nil)
    SaleItem.transaction do
      sale_item = SaleItem.lock.find(sale_item_id)
      return :noop unless integrity.broken_sale_item?(sale_item.id)

      product, variant = lock_repair_candidate!(sale_item, variant_id, product_id:)
      sale_items = SaleItem.where(id: sale_item.id).order(id: :asc).lock.to_a
      purchase_items = lock_relevant_purchase_items(
        required_ids: sale_item.purchase_items.ids,
        sale_items:,
        additional_identities: [[product.id, variant.id]]
      )
      return :noop unless integrity.broken_sale_item?(sale_item.id)
      ensure_source_sale_items_locked!(purchase_items, sale_items)

      # Historical repair must bypass normal assignability callbacks and notifications.
      sale_item.update_columns( # rubocop:disable Rails/SkipsModelValidations
        product_id: product.id,
        variant_id: variant.id,
        updated_at: Time.current
      ) # rubocop:enable Rails/SkipsModelValidations
      sale_items.first.assign_attributes(product_id: product.id, variant_id: variant.id)

      reconcile_locked_links!(sale_items:, purchase_items:)
      :repaired
    end
  end

  def repair_purchase_item_link!(purchase_item_id:)
    PurchaseItem.transaction do
      link = PurchaseItem.find(purchase_item_id)
      sale_item_id = link.sale_item_id
      return :noop if sale_item_id.blank?

      sale_items = SaleItem.where(id: sale_item_id).order(id: :asc).lock.to_a
      purchase_items = lock_relevant_purchase_items(
        required_ids: [purchase_item_id],
        sale_items:
      )
      return :noop unless integrity.incompatible_purchase_item_link?(purchase_item_id)
      ensure_source_sale_items_locked!(purchase_items, sale_items)

      reconcile_locked_links!(sale_items:, purchase_items:)
      :repaired
    end
  end

  def repair_purchase_item_identity!(purchase_item_id:)
    PurchaseItem.transaction do
      purchase_item = PurchaseItem.find(purchase_item_id)
      purchase = Purchase.lock.find(purchase_item.purchase_id)
      return :noop unless integrity.purchase_item_purchase_identity_mismatch?(purchase_item.id)

      sale_items = lock_relevant_sale_items(
        source_ids: [purchase_item.sale_item_id],
        target_relation: fillable_sale_items(
          product_id: purchase.product_id,
          variant_id: purchase.variant_id
        )
      )
      purchase_items = lock_relevant_purchase_items(
        required_ids: [purchase_item.id],
        sale_items:,
        additional_identities: [[purchase.product_id, purchase.variant_id]]
      )
      locked_purchase_item = purchase_items.find { |item| item.id == purchase_item.id }
      return :noop unless integrity.purchase_item_purchase_identity_mismatch?(purchase_item.id)

      ensure_source_sale_items_locked!(purchase_items, sale_items)
      locked_purchase_item.update_columns( # rubocop:disable Rails/SkipsModelValidations
        product_id: purchase.product_id,
        variant_id: purchase.variant_id,
        updated_at: Time.current
      ) # rubocop:enable Rails/SkipsModelValidations
      locked_purchase_item.assign_attributes(
        product_id: purchase.product_id,
        variant_id: purchase.variant_id
      )

      reconcile_locked_links!(sale_items:, purchase_items:)
      :repaired
    end
  end

  def reconcile_duplicate_shopify_identity!(store_id:, canonical_store_info_id:)
    StoreInfo.transaction do
      unlocked_infos = duplicate_shopify_infos(store_id).order(id: :asc).to_a
      return noop_shopify_identity_reconciliation if unlocked_infos.size <= 1

      canonical_info = unlocked_infos.find { |info| info.id == canonical_store_info_id }
      raise InvalidCandidate, "Canonical Shopify StoreInfo is not in the duplicate group" unless canonical_info

      canonical_variant = Variant.find(canonical_info.storable_id)
      losing_variant_ids = unlocked_infos.filter_map do |info|
        info.storable_id unless info.id == canonical_info.id
      end
      purchase_ids = Purchase
        .where(product_id: canonical_variant.product_id, variant_id: losing_variant_ids)
        .order(:id)
        .ids
      sale_item_ids = SaleItem
        .where(product_id: canonical_variant.product_id, variant_id: losing_variant_ids)
        .order(:id)
        .ids
      variant_ids = unlocked_infos.pluck(:storable_id)
      product_ids = Variant.where(id: variant_ids).distinct.pluck(:product_id)

      # Reconciliation lock order is Purchases, SaleItems, Products, Variants,
      # then StoreInfos. The parent-before-Product prefix matches the individual
      # Purchase and SaleItem repair commands and prevents their lock inversion.
      Purchase.where(id: purchase_ids).order(id: :asc).lock.load
      SaleItem.where(id: sale_item_ids).order(id: :asc).lock.load
      Product.where(id: product_ids).order(id: :asc).lock.load
      Variant.where(id: variant_ids).order(id: :asc).lock.load
      locked_infos = duplicate_shopify_infos(store_id).order(id: :asc).lock.to_a
      unless locked_infos.pluck(:id) == unlocked_infos.pluck(:id)
        raise InvalidCandidate, "Shopify duplicate group changed before reconciliation"
      end

      canonical_info = canonical_shopify_info(locked_infos)
      unless canonical_info&.id == canonical_store_info_id
        raise InvalidCandidate, "Canonical Shopify StoreInfo changed before reconciliation"
      end

      canonical_variant = Variant.find(canonical_info.storable_id)
      losing_variant_ids = locked_infos.filter_map do |info|
        info.storable_id unless info.id == canonical_info.id
      end
      locked_purchase_ids = Purchase
        .where(product_id: canonical_variant.product_id, variant_id: losing_variant_ids)
        .order(:id)
        .ids
      locked_sale_item_ids = SaleItem
        .where(product_id: canonical_variant.product_id, variant_id: losing_variant_ids)
        .order(:id)
        .ids
      unless locked_purchase_ids == purchase_ids && locked_sale_item_ids == sale_item_ids
        raise InvalidCandidate, "Shopify dependent assignments changed before reconciliation"
      end

      repaired_purchase_count = repair_purchases_to_variant!(
        locked_purchase_ids,
        canonical_variant
      )
      repaired_sale_item_count = repair_sale_items_to_variant!(
        locked_sale_item_ids,
        canonical_variant
      )
      stale_infos = locked_infos.reject { |info| info.id == canonical_info.id }
      stale_infos.each(&:destroy!)

      ShopifyIdentityReconciliation.new(
        removed_store_info_count: stale_infos.size,
        repaired_purchase_count:,
        repaired_sale_item_count:
      )
    end
  end

  private

  attr_reader :integrity

  def lock_repair_candidate!(record, variant_id, product_id: nil)
    product = product_id ? Product.find_by(id: product_id) : record.product || record.variant&.product
    raise InvalidCandidate, "No Product is available for this repair" unless product

    product = Product.lock.find(product.id)
    variant = product.variant_repair_candidates.lock.find_by(id: variant_id)
    raise InvalidCandidate, "Variant is not an available repair candidate" unless variant

    [product, variant]
  end

  def lock_relevant_sale_items(source_ids:, target_relation:)
    ids = (Array(source_ids) + target_relation.ids).compact.uniq.sort
    SaleItem.where(id: ids).order(id: :asc).lock.to_a
  end

  def lock_relevant_purchase_items(required_ids:, sale_items:, additional_identities: [])
    ids = Array(required_ids)
    ids.concat(PurchaseItem.where(sale_item_id: sale_items.pluck(:id)).ids)
    sale_items.each do |sale_item|
      additional_identities << [sale_item.product_id, sale_item.variant_id]
    end
    additional_identities.uniq.each do |product_id, variant_id|
      ids.concat(
        PurchaseItem.where(
          sale_item_id: nil,
          product_id:,
          variant_id:
        ).ids
      )
    end

    PurchaseItem.where(id: ids.compact.map(&:to_i).uniq.sort).order(id: :asc).lock.to_a
  end

  def fillable_sale_items(product_id:, variant_id:)
    SaleItem
      .active
      .where(origin_sale_item_id: nil, product_id:, variant_id:)
      .order(id: :asc)
  end

  def ensure_source_sale_items_locked!(purchase_items, sale_items)
    unlocked_source_ids =
      purchase_items.pluck(:sale_item_id).compact.uniq - sale_items.pluck(:id)
    return if unlocked_source_ids.empty?

    raise PurchaseItem::Linking::StaleLinkState,
      "PurchaseItem link state changed before all source SaleItems could be locked"
  end

  def reconcile_locked_links!(sale_items:, purchase_items:)
    sale_items_by_id = sale_items.index_by(&:id)

    purchase_items.each do |purchase_item|
      next if purchase_item.sale_item_id.blank?

      sale_item = sale_items_by_id[purchase_item.sale_item_id]
      next if sale_item && exact_identity?(purchase_item, sale_item)

      update_repair_link!(purchase_item, nil)
    end

    fillable_ids = SaleItem
      .active
      .where(id: sale_items.pluck(:id), origin_sale_item_id: nil)
      .ids

    sale_items.sort_by(&:id).each do |sale_item|
      next unless fillable_ids.include?(sale_item.id)

      linked_count = purchase_items.count { |purchase_item| purchase_item.sale_item_id == sale_item.id }
      remaining_capacity = sale_item.qty.to_i - linked_count
      next unless remaining_capacity.positive?

      purchase_items
        .select { |purchase_item|
          purchase_item.sale_item_id.blank? && exact_identity?(purchase_item, sale_item)
        }
        .sort_by { |purchase_item| [purchase_item.created_at, purchase_item.id] }
        .first(remaining_capacity)
        .each { |purchase_item| update_repair_link!(purchase_item, sale_item) }
    end
  end

  def exact_identity?(purchase_item, sale_item)
    purchase_item.product_id.present? &&
      purchase_item.variant_id.present? &&
      sale_item.product_id.present? &&
      sale_item.variant_id.present? &&
      purchase_item.product_id == sale_item.product_id &&
      purchase_item.variant_id == sale_item.variant_id
  end

  def update_repair_link!(purchase_item, sale_item)
    if purchase_item.product_id.blank? || purchase_item.variant_id.blank?
      purchase_item.sale_item = sale_item
      purchase_item.save!(validate: false)
    else
      purchase_item.update!(sale_item:)
    end
  end

  def duplicate_shopify_infos(store_id)
    StoreInfo.shopify.where(
      storable_type: "Variant",
      store_id:
    )
  end

  def canonical_shopify_info(infos)
    with_pull_provenance = infos.select do |info|
      info.pull_time.present? ||
        info.ext_created_at.present? ||
        info.ext_updated_at.present?
    end
    with_pull_provenance.one? ? with_pull_provenance.first : nil
  end

  def noop_shopify_identity_reconciliation
    ShopifyIdentityReconciliation.new(
      removed_store_info_count: 0,
      repaired_purchase_count: 0,
      repaired_sale_item_count: 0
    )
  end

  def repair_purchases_to_variant!(purchase_ids, canonical_variant)
    purchase_ids.count do |purchase_id|
      repair_purchase!(
        purchase_id:,
        variant_id: canonical_variant.id
      ) == :repaired
    end
  end

  def repair_sale_items_to_variant!(sale_item_ids, canonical_variant)
    sale_item_ids.count do |sale_item_id|
      repair_sale_item!(
        sale_item_id:,
        variant_id: canonical_variant.id,
        product_id: canonical_variant.product_id
      ) == :repaired
    end
  end
end
