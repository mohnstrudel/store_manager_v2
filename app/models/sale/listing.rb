# frozen_string_literal: true

module Sale::Listing
  extend ActiveSupport::Concern

  SHOP_CREATED_AT_SQL = "COALESCE(sales.shopify_created_at, sales.woo_created_at, sales.created_at)"

  included do
    scope :ordered_by_shop_created_at, -> {
      order(
        Arel.sql("#{SHOP_CREATED_AT_SQL} DESC")
      )
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
          {purchase_items: [:warehouse, {purchase: :supplier}]},
          {variant: [:version, :color, :size]}
        ]
      )
    }
  end
end
