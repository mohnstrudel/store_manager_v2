# frozen_string_literal: true

module PurchaseItem::Linking
  extend ActiveSupport::Concern

  IdentityMismatch = Class.new(StandardError)
  CapacityExceeded = Class.new(StandardError)
  StaleLinkState = Class.new(StandardError)

  included do
    scope :available_for_product_linking, ->(product_id) {
      paid_priority = Arel.sql(
        "CASE WHEN purchases.payments_count > 0 THEN 0 ELSE 1 END ASC"
      )
      where(sale_item_id: nil)
        .joins(:purchase)
        .where(purchases: {product_id:})
        .order(paid_priority, created_at: :asc)
    }
  end

  class_methods do
    def link_available_to_sale_items!(sale_items:, purchase_items: all)
      reserved_purchase_item_ids = []
      assignments = Array(sale_items).sort_by(&:id).flat_map do |sale_item|
        remaining_capacity = sale_item.qty.to_i - sale_item.purchase_items.count
        next [] unless remaining_capacity.positive?

        candidates = available_for_product_linking(sale_item.product_id)
          .where(variant_id: sale_item.variant_id)
          .where(id: purchase_items)
          .where.not(id: reserved_purchase_item_ids)
          .limit(remaining_capacity)
          .to_a
        reserved_purchase_item_ids.concat(candidates.pluck(:id))
        candidates.map { |purchase_item| {purchase_item:, sale_item:} }
      end

      link_exact!(assignments:)
    end

    def reconcile_identity_change!(parent)
      transaction do
        case parent
        when Purchase
          reconcile_purchase_identity_change!(parent) { yield }
        when SaleItem
          reconcile_sale_item_identity_change!(parent) { yield }
        else
          raise ArgumentError, "Unsupported identity owner: #{parent.class.name}"
        end
      end
    end

    def link_exact!(assignments:, unlink_purchase_items: [])
      normalized_assignments = normalize_assignments(assignments)
      requested_purchase_items = normalized_assignments.values.pluck(:purchase_item)
      requested_sale_items = normalized_assignments.values.pluck(:sale_item)
      requested_unlinks = Array(unlink_purchase_items)
      notification_ids = []

      transaction do
        sale_item_ids = (
          requested_sale_items.pluck(:id) +
          requested_purchase_items.pluck(:sale_item_id) +
          requested_unlinks.pluck(:sale_item_id)
        ).compact.uniq.sort

        locked_sale_items = SaleItem.where(id: sale_item_ids).order(id: :asc).lock.to_a
        ensure_all_found!(locked_sale_items, sale_item_ids, SaleItem)

        purchase_item_ids = (
          requested_purchase_items.pluck(:id) +
          requested_unlinks.pluck(:id) +
          where(sale_item_id: sale_item_ids).pluck(:id)
        ).uniq.sort
        locked_purchase_items = where(id: purchase_item_ids).order(id: :asc).lock.to_a
        ensure_all_found!(locked_purchase_items, purchase_item_ids, self)
        ensure_source_sale_items_locked!(locked_purchase_items, sale_item_ids)

        sale_items_by_id = locked_sale_items.index_by(&:id)
        purchase_items_by_id = locked_purchase_items.index_by(&:id)
        assignments_by_id = normalized_assignments.transform_values do |assignment|
          sale_items_by_id.fetch(assignment.fetch(:sale_item).id)
        end
        unlink_ids = requested_unlinks.pluck(:id).uniq - assignments_by_id.keys

        validate_exact_identity!(assignments_by_id, purchase_items_by_id)
        validate_capacity!(
          assignments_by_id:,
          unlink_ids:,
          purchase_items: locked_purchase_items,
          sale_items_by_id:
        )

        original_sale_item_ids = purchase_items_by_id.transform_values(&:sale_item_id)

        unlink_ids.each do |purchase_item_id|
          purchase_items_by_id.fetch(purchase_item_id).update!(sale_item: nil)
        end

        assignments_by_id.each do |purchase_item_id, sale_item|
          purchase_item = purchase_items_by_id.fetch(purchase_item_id)
          next if purchase_item.sale_item_id == sale_item.id

          purchase_item.update!(sale_item:)
          notification_ids << purchase_item.id
        end

        notification_ids.select! do |purchase_item_id|
          original_sale_item_ids.fetch(purchase_item_id) != assignments_by_id.fetch(purchase_item_id).id
        end
        notification_ids.uniq!

        schedule_link_notifications(notification_ids)
      end

      notification_ids
    end

    private

    def reconcile_purchase_identity_change!(purchase)
      incompatible_purchase_items = purchase.purchase_items
        .joins(:sale_item)
        .where.not(
          sale_items: {
            product_id: purchase.product_id,
            variant_id: purchase.variant_id
          }
        )
        .to_a

      link_exact!(assignments: [], unlink_purchase_items: incompatible_purchase_items)
      yield
      purchase.purchase_items.update_all(
        product_id: purchase.product_id,
        variant_id: purchase.variant_id,
        updated_at: Time.current
      )
      purchase.link_purchase_items
    end

    def reconcile_sale_item_identity_change!(sale_item)
      incompatible_purchase_items = sale_item.purchase_items
        .where.not(
          product_id: sale_item.product_id,
          variant_id: sale_item.variant_id
        )
        .to_a

      link_exact!(assignments: [], unlink_purchase_items: incompatible_purchase_items)
      yield
      link_available_to_sale_items!(sale_items: [sale_item])
    end

    def normalize_assignments(assignments)
      Array(assignments).each_with_object({}) do |assignment, normalized|
        purchase_item = assignment.fetch(:purchase_item)
        sale_item = assignment.fetch(:sale_item)
        purchase_item_id = purchase_item.id
        existing = normalized[purchase_item_id]

        if existing && existing.fetch(:sale_item).id != sale_item.id
          raise ArgumentError, "PurchaseItem #{purchase_item.id} has conflicting link targets"
        end

        normalized[purchase_item_id] = {purchase_item:, sale_item:}
      end
    end

    def ensure_all_found!(records, requested_ids, model)
      missing_ids = requested_ids - records.pluck(:id)
      return if missing_ids.empty?

      raise ActiveRecord::RecordNotFound, "Couldn't find #{model.name} with IDs #{missing_ids.join(", ")}"
    end

    def validate_exact_identity!(assignments_by_id, purchase_items_by_id)
      assignments_by_id.each do |purchase_item_id, sale_item|
        purchase_item = purchase_items_by_id.fetch(purchase_item_id)
        next if exact_identity?(purchase_item, sale_item)

        raise IdentityMismatch,
          "PurchaseItem #{purchase_item.id} does not exactly match SaleItem #{sale_item.id}"
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

    def ensure_source_sale_items_locked!(purchase_items, locked_sale_item_ids)
      unlocked_source_ids = purchase_items.pluck(:sale_item_id).compact.uniq - locked_sale_item_ids
      return if unlocked_source_ids.empty?

      raise StaleLinkState,
        "PurchaseItem link state changed before all source SaleItems could be locked"
    end

    def validate_capacity!(assignments_by_id:, unlink_ids:, purchase_items:, sale_items_by_id:)
      final_sale_item_ids = purchase_items.to_h do |purchase_item|
        target_id =
          if assignments_by_id.key?(purchase_item.id)
            assignments_by_id.fetch(purchase_item.id).id
          elsif unlink_ids.include?(purchase_item.id)
            nil
          else
            purchase_item.sale_item_id
          end

        [purchase_item.id, target_id]
      end

      final_counts = final_sale_item_ids.values.compact.tally
      sale_items_by_id.each_value do |sale_item|
        next if final_counts.fetch(sale_item.id, 0) <= sale_item.qty.to_i

        raise CapacityExceeded, "SaleItem #{sale_item.id} has no remaining link capacity"
      end
    end

    def schedule_link_notifications(purchase_item_ids)
      return if purchase_item_ids.empty?

      ActiveRecord.after_all_transactions_commit do
        PurchaseItem.notify_order_status!(purchase_item_ids:)
      end
    end
  end

  def link_to_sale_item!(sale_item_id)
    self.class.link_exact!(
      assignments: [{purchase_item: self, sale_item: SaleItem.find(sale_item_id)}]
    )
  end

  def unlink_from_sale_item!
    self.class.link_exact!(assignments: [], unlink_purchase_items: [self])
  end
end
