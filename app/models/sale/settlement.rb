# frozen_string_literal: true

# Normalizes provider-specific payment evidence into one persisted
# settlement_status: paid, not_fully_paid, or unknown. settlement_status
# stays NULL until a synchronization converts and classifies the sale — see
# ExchangeRate for the USD conversion boundary this status is written
# alongside.
#
# Settlement classification is independent from whether a sale counts
# toward positive economics: a cancelled, voided, or fully refunded sale
# still gets a real settlement_status (whatever its payment evidence maps
# to), and is separately excluded from positive economics by
# `economically_excluded`/`economically_included`.
module Sale::Settlement
  extend ActiveSupport::Concern

  # Shopify displayFinancialStatus values where the order's own balance
  # evidence, not the label, decides settlement: money was captured at some
  # point, so zero outstanding means paid.
  FULLY_COLLECTED_SHOPIFY_FINANCIAL_STATUSES = %w[PAID PARTIALLY_REFUNDED REFUNDED].freeze

  # Shopify displayFinancialStatus values that never mean fully collected,
  # regardless of outstanding evidence.
  NOT_FULLY_PAID_SHOPIFY_FINANCIAL_STATUSES = %w[
    PENDING AUTHORIZED PARTIALLY_AUTHORIZED PARTIALLY_PAID VOIDED EXPIRED
  ].freeze

  included do
    enum :settlement_status, {paid: "paid", not_fully_paid: "not_fully_paid", unknown: "unknown"},
      validate: {allow_nil: true}

    scope :fully_refunded, -> {
      where.not(refunded_revenue: nil).where.not(total: nil).where("refunded_revenue >= total")
    }

    # Cancelled, failed, voided, and fully refunded sales — excluded from
    # positive economics by existing cancellation, status, and refund
    # state, never by settlement_status itself.
    scope :economically_excluded, -> {
      where(status: cancelled_status_names)
        .or(where(status: "refunded"))
        .or(where(financial_status: "VOIDED"))
        .or(fully_refunded)
    }

    scope :economically_included, -> { where.not(id: economically_excluded) }
  end

  class_methods do
    # Maps Shopify's authoritative financial-status and outstanding-balance
    # evidence to the normalized settlement_status. Positive outstanding
    # revenue always wins, even over a financial status that usually means
    # fully collected, because outstanding is Shopify's own balance-due
    # figure. An unmapped financial status raises so a manually triggered
    # synchronization never silently persists a placeholder.
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
  end
end
