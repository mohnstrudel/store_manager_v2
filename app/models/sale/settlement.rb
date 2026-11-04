# frozen_string_literal: true

module Sale::Settlement
  extend ActiveSupport::Concern

  included do
    enum :settlement_status, {paid: "paid", not_fully_paid: "not_fully_paid", unknown: "unknown"},
      validate: {allow_nil: true}

    scope :fully_refunded, -> {
      where.not(refunded_revenue: nil).where.not(total: nil).where("refunded_revenue >= total")
    }

    scope :economically_excluded, -> {
      where(status: Sale::CANCELLED_STATUSES)
        .or(where(status: "refunded"))
        .or(where(financial_status: "VOIDED"))
        .or(fully_refunded)
    }

    scope :economically_included, -> { where.not(id: economically_excluded) }
    scope :uncancelled, -> { where.not(status: Sale::CANCELLED_STATUSES) }
  end

  class_methods do
    def shop_created_expr
      sales = arel_table
      Arel::Nodes::NamedFunction.new(
        "COALESCE",
        [sales[:shopify_created_at], sales[:woo_created_at], sales[:created_at]]
      )
    end
  end

  def economically_excluded?
    cancelled? || status == "refunded" || financial_status == "VOIDED" || fully_refunded?
  end

  def fully_refunded?
    refunded_revenue.present? && total.present? && refunded_revenue >= total
  end

  def partially_paid?
    received_revenue.to_d.positive? && outstanding_revenue.to_d.positive?
  end
end
