# frozen_string_literal: true

module Sale::Filterable
  extend ActiveSupport::Concern

  SHOP_CREATED_AT_SQL = "COALESCE(sales.shopify_created_at, sales.woo_created_at, sales.created_at)"
  SORT_DIRECTIONS = {"newest" => :desc, "oldest" => :asc}.freeze

  class_methods do
    def listing_sort(value)
      SORT_DIRECTIONS.key?(value) ? value : "newest"
    end

    def listing(query:, sort:, hide_partial_payments: false, missing_purchases_only: false, tag_id: nil)
      matches = for_listing.except_cancelled_or_completed.search_by(query)
      matches = matches.tagged_with(tag_id) if tag_id
      matches = matches.without_follow_up_payments if hide_partial_payments
      matches = matches.with_missing_purchases if missing_purchases_only
      matches.sorted_by(sort)
    end
  end

  included do
    scope :ordered_by_shop_created_at, -> {
      order(
        Arel.sql("#{SHOP_CREATED_AT_SQL} DESC")
      )
    }

    scope :sorted_by, ->(sort) {
      direction = SORT_DIRECTIONS.fetch(listing_sort(sort))
      reorder(shop_created_expr.public_send(direction), arel_table[:id].public_send(direction))
    }
  end
end
