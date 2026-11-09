# frozen_string_literal: true

module Sale::Statuses
  extend ActiveSupport::Concern

  ACTIVE_STATUSES = [
    "partially-paid",
    "po_fully_paid",
    "pre-ordered",
    "processing",
    "ready-to-fullfill",
    "im-zulauf",
    "container-shipped"
  ].freeze

  COMPLETED_STATUSES = ["completed", "updated-tracking"].freeze

  CANCELLED_STATUSES = ["cancelled", "failed"].freeze

  STATUSES = [
    "auto-draft",
    "cancelled",
    "checkout-draft",
    "completed",
    "container-shipped",
    "failed",
    "im-zulauf",
    "on-hold",
    "partial-shipped",
    "partially-paid",
    "pending",
    "po_fully_paid",
    "pre-ordered",
    "processing",
    "ready-to-fullfill",
    "refunded",
    "trash",
    "updated-tracking"
  ].freeze

  included do
    scope :except_cancelled_or_completed, -> {
      where.not(status: CANCELLED_STATUSES + COMPLETED_STATUSES)
    }

    scope :active, -> {
      where(status: ACTIVE_STATUSES)
    }

    scope :completed, -> {
      where(status: COMPLETED_STATUSES)
    }
  end

  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def completed?
    COMPLETED_STATUSES.include?(status)
  end

  def cancelled?
    CANCELLED_STATUSES.include?(status)
  end

  def item_tracking_payload
    sale_items.with_tracking_sources.map do |sale_item|
      purchase_item = sale_item.purchase_items.first
      status = nil
      description = nil

      if purchase_item&.warehouse_id.present?
        warehouse = purchase_item.warehouse
        status = warehouse.external_name_de.presence || warehouse.external_name_en.presence || "No status available"
        description = warehouse.desc_de.presence || warehouse.desc_en.presence || "No description available"
      end

      {productName: sale_item.title, status:, description:}
    end
  end

  def movement_statuses
    Warehouse
      .joins(purchase_items: :sale_item)
      .where(sale_items: {sale_id: id})
      .distinct
      .pluck(:name)
      .join(", ")
      .presence
  end
end
