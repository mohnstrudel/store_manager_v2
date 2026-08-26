# frozen_string_literal: true

# Settlement classification is independent from economic inclusion.
module Sale::Settlement
  extend ActiveSupport::Concern

  FULLY_COLLECTED_SHOPIFY_FINANCIAL_STATUSES = %w[PAID PARTIALLY_REFUNDED REFUNDED].freeze

  NOT_FULLY_PAID_SHOPIFY_FINANCIAL_STATUSES = %w[
    PENDING AUTHORIZED PARTIALLY_AUTHORIZED PARTIALLY_PAID VOIDED EXPIRED
  ].freeze

  KNOWN_WOO_STATUSES = %w[
    pending processing on-hold completed cancelled refunded failed trash checkout-draft auto-draft
  ].freeze

  WOO_PARTIALLY_PAID_STATUS = "partially-paid"

  included do
    enum :settlement_status, {paid: "paid", not_fully_paid: "not_fully_paid", unknown: "unknown"},
      validate: {allow_nil: true}

    scope :fully_refunded, -> {
      where.not(refunded_revenue: nil).where.not(total: nil).where("refunded_revenue >= total")
    }

    scope :economically_excluded, -> {
      where(status: cancelled_status_names)
        .or(where(status: "refunded"))
        .or(where(financial_status: "VOIDED"))
        .or(fully_refunded)
    }

    scope :economically_included, -> { where.not(id: economically_excluded) }
  end

  class_methods do
    def settlement_status_from_shopify(financial_status:, outstanding_revenue:)
      return "not_fully_paid" if outstanding_revenue.to_d.positive?

      case financial_status
      when *FULLY_COLLECTED_SHOPIFY_FINANCIAL_STATUSES
        "paid"
      when *NOT_FULLY_PAID_SHOPIFY_FINANCIAL_STATUSES
        "not_fully_paid"
      else
        raise ArgumentError, "Unmapped Shopify financial status: #{financial_status.inspect}"
      end
    end

    def settlement_status_from_woo(status:, date_paid:)
      return "not_fully_paid" if status == WOO_PARTIALLY_PAID_STATUS

      case status
      when *KNOWN_WOO_STATUSES
        date_paid.present? ? "paid" : "not_fully_paid"
      else
        raise ArgumentError, "Unmapped Woo status: #{status.inspect}"
      end
    end
  end
end
