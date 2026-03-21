# frozen_string_literal: true

module Sale::Statuses
  extend ActiveSupport::Concern

  included do
    scope :except_cancelled_or_completed, -> {
      where.not(status: cancelled_status_names + completed_status_names)
    }

    scope :active, -> {
      where(status: active_status_names)
    }

    scope :completed, -> {
      where(status: completed_status_names)
    }
  end

  class_methods do
    def active_status_names
      [
        "partially-paid",
        "po_fully_paid",
        "pre-ordered",
        "processing",
        "ready-to-fullfill",
        "im-zulauf",
        "container-shipped"
      ].freeze
    end

    def completed_status_names
      ["completed", "updated-tracking"].freeze
    end

    def cancelled_status_names
      ["cancelled", "failed"].freeze
    end

    def status_names
      [
        "cancelled",
        "completed",
        "container-shipped",
        "failed",
        "im-zulauf",
        "on-hold",
        "partial-shipped",
        "partially-paid",
        "po_fully_paid",
        "pre-ordered",
        "processing",
        "ready-to-fullfill",
        "refunded",
        "updated-tracking"
      ].freeze
    end

    def inactive_status_names
      status_names - active_status_names - completed_status_names
    end

    def derive_status_from_shopify(fulfillment_status, financial_status)
      case [fulfillment_status, financial_status]
      when ["FULFILLED", "PAID"]
        "completed"
      when ["UNFULFILLED", "PAID"]
        "pre-ordered"
      when ["UNFULFILLED", "PENDING"]
        "processing"
      when ["UNFULFILLED", "PARTIALLY_PAID"]
        "partially-paid"
      when ["FULFILLED", "REFUNDED"]
        "refunded"
      when ["UNFULFILLED", "REFUNDED"]
        "cancelled"
      else
        "processing"
      end
    end
  end

  def active?
    self.class.active_status_names.include?(status)
  end

  def completed?
    self.class.completed_status_names.include?(status)
  end
end
