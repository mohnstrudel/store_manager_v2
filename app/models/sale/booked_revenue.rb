# frozen_string_literal: true

module Sale::BookedRevenue
  extend ActiveSupport::Concern

  included do
    scope :uncancelled, -> { where.not(status: cancelled_status_names) }
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
end
