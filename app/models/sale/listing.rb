# frozen_string_literal: true

module Sale::Listing
  extend ActiveSupport::Concern

  SHOP_CREATED_AT_SQL = "COALESCE(sales.shopify_created_at, sales.woo_created_at, sales.created_at)"
  SORT_DIRECTIONS = {"newest" => :desc, "oldest" => :asc}.freeze

  class_methods do
    def listing_sort(value)
      SORT_DIRECTIONS.key?(value) ? value : "newest"
    end

    def listing(query:, sort:, hide_partial_payments: false, missing_purchases_only: false)
      matches = for_listing.except_cancelled_or_completed.search_by(query)
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

    scope :for_listing, -> {
      includes(
        :customer,
        :shopify_info,
        :woo_info,
        :shipping_address,
        :billing_address,
        {origin_payment_plans: [:origin_sale, {parts: :sale}]},
        {sale_payment_parts: {sale_payment_plan: [:origin_sale, {parts: :sale}]}},
        sale_items: [
          {product: {media: {image_attachment: :blob}}},
          {purchase_items: [:warehouse, purchase: :supplier]},
          {variant: [:version, :color, :size]}
        ]
      )
    }

    scope :for_edit, -> {
      includes(:sale_items, :shipping_address, :billing_address)
    }

    scope :for_details, -> {
      includes(
        :customer,
        :shopify_info,
        :woo_info,
        :shipping_address,
        :billing_address,
        {origin_payment_plans: [:origin_sale, {parts: :sale}]},
        {sale_payment_parts: {sale_payment_plan: [:origin_sale, {parts: :sale}]}},
        sale_items: [
          {product: {media: {image_attachment: :blob}}},
          {purchase_items: [:warehouse, :shipping_company, {purchase: :supplier}]},
          {variant: [:version, :color, :size]}
        ]
      )
    }
  end
end
