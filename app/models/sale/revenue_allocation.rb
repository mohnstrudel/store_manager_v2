# frozen_string_literal: true

# Distributes order-level Shopify payment amounts across sale items
# proportionally by each item's expected line revenue, so profitability
# can be evaluated per product even for multi-product orders.
module Sale::RevenueAllocation
  extend ActiveSupport::Concern

  ALLOCATED_FIELDS = %i[received_revenue outstanding_revenue refunded_revenue].freeze

  # Only the amounts the order actually states are distributed. A Woo deposit
  # states its refunds but not its payment split, and splitting an unset amount
  # would write zeros onto every item — a second source of truth contradicting
  # the order itself.
  def allocate_revenue_to_items!
    known_fields = ALLOCATED_FIELDS.reject { |field| public_send(field).nil? }
    return if known_fields.empty?

    items = sale_items.order(:id).to_a
    return if items.empty?

    shares = revenue_shares(items)
    allocations = known_fields.index_with { |field| split_amount(public_send(field), shares) }

    items.each_with_index do |item, index|
      item.update!(allocations.transform_values { |amounts| amounts[index] })
    end
  end

  # A store can report what an order is worth without reporting how much of it
  # was collected: WooCommerce marks a deposit order paid but never names the
  # deposit. Readers have to say "unknown" instead of "nothing received".
  def payment_split_unknown?
    expected_revenue.present? && received_revenue.nil? && outstanding_revenue.nil?
  end

  # Read-only counterpart to allocate_revenue_to_items!: shipping isn't one of
  # ALLOCATED_FIELDS (it's never persisted onto items), so this derives each
  # item's proportional share on demand using the same weights.
  def shipping_shares_by_item_id
    items = sale_items.to_a.sort_by(&:id)
    return {} if items.empty?

    shares = revenue_shares(items)
    items.map(&:id).zip(split_amount(shipping_total, shares)).to_h
  end

  private

  def revenue_shares(items)
    line_totals = items.map { |item| item.expected_revenue.to_d }
    total = line_totals.sum

    return Array.new(items.size, 1.to_d / items.size) if total.zero?

    line_totals.map { |line_total| line_total / total }
  end

  # Rounds every share to cents and gives the remainder to the last item,
  # so the allocated amounts always sum to the order-level amount.
  def split_amount(total, shares)
    total = total.to_d
    amounts = shares.map { |share| (total * share).round(2) }
    amounts[-1] = total - amounts[0..-2].sum
    amounts
  end
end
