# frozen_string_literal: true

# Sale::InstallmentProductResolver
#
# Resolves which real product an installment/deposit charge actually belongs
# to, when the Shopify line item points at a non-catalog placeholder product
# (e.g. Seal Subscriptions' generic "Partial Payment" product). Two signals,
# tried in order:
#
# 1. This sale's customer bought exactly one other real product — use it. If
#    they bought several, narrow by matching this sale's exact total against
#    one of their other orders.
# 2. Seal Subscriptions' Merchant API, when neither heuristic can decide.
#
# Used both at Shopify import time (Sale::Shopify::SaleItemImporter) and by
# the one-time backfill task for sale items already stuck on a placeholder.
class Sale::InstallmentProductResolver
  def initialize(sale)
    @sale = sale
  end

  def target_product
    return @target_product if defined?(@target_product)

    @target_product = product_from_customer_heuristic || product_from_seal_subscription
  end

  # The sale item that represents the real unit this charge is paying
  # towards, so the caller can link the installment to it.
  def origin_sale_item
    return nil if target_product.blank?

    SaleItem
      .non_installment
      .joins(:sale)
      .where(sales: {customer_id: sale.customer_id}, product_id: target_product.id)
      .order(:created_at)
      .first
  end

  private

  attr_reader :sale

  def product_from_customer_heuristic
    return nil if sale.customer_id.blank?

    candidate_ids = customer_real_product_ids
    return nil if candidate_ids.empty?
    return Product.find(candidate_ids.first) if candidate_ids.one?

    matched_id = customer_product_id_by_exact_amount(candidate_ids)
    matched_id && Product.find(matched_id)
  end

  def customer_real_product_ids
    SaleItem
      .joins(:sale, :product)
      .where(sales: {customer_id: sale.customer_id})
      .where(products: {non_catalog: false})
      .where.not(sale_id: sale.id)
      .distinct
      .pluck(:product_id)
  end

  def customer_product_id_by_exact_amount(candidate_ids)
    matches = Sale
      .joins(:sale_items)
      .where(customer_id: sale.customer_id, total: sale.total)
      .where(sale_items: {product_id: candidate_ids})
      .distinct
      .pluck("sale_items.product_id")
      .uniq

    matches.first if matches.one?
  end

  # Seal's own subscription record always lists its billing item as the
  # generic placeholder product (that's what gets charged each installment),
  # so it can't tell us the real product. The real product(s) live on the
  # subscription's origin order in Shopify. When that order has exactly one
  # distinct real product, this payment plan is unambiguously for it; when it
  # bundles several, there's no way to attribute a single installment to one
  # of them, so this returns nil and the caller falls through to the
  # placeholder.
  def product_from_seal_subscription
    subscription = Seal::Api::Client.shared.find_subscription_for_order(sale.shopify_store_id)
    return nil if subscription.blank?

    real_product_store_id = single_real_product_store_id(subscription["order_id"])
    return nil if real_product_store_id.blank?

    Product.find_by_shopify_id(real_product_store_id) || pull_shopify_product(real_product_store_id)
  rescue Seal::Api::Client::ApiError, Shopify::Api::Client::ApiError => e
    Sentry.capture_exception(e)
    nil
  end

  def single_real_product_store_id(origin_order_id)
    return nil if origin_order_id.blank?

    order = Shopify::Api::Client.new.fetch_order("gid://shopify/Order/#{origin_order_id}")
    return nil if order.blank?

    product_store_ids = Array(order.dig("lineItems", "nodes")).filter_map { |item| item.dig("product", "id") }.uniq
    real_product_store_ids = product_store_ids - non_catalog_shopify_ids
    real_product_store_ids.first if real_product_store_ids.one?
  end

  def non_catalog_shopify_ids
    Product.where(non_catalog: true).pluck(:shopify_id)
  end

  def pull_shopify_product(product_store_id)
    payload = Shopify::Api::Client.new.fetch_product(product_store_id)
    return nil if payload.blank?

    Product::Shopify::Importer.import!(Product::Shopify::Parser.parse(payload))
  end
end
