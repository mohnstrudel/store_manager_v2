# frozen_string_literal: true

module Sale::RevenueAllocation
  extend ActiveSupport::Concern

  ALLOCATED_FIELDS = %i[received_revenue outstanding_revenue refunded_revenue].freeze

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

  def payment_split_unknown?
    expected_revenue.present? && received_revenue.nil? && outstanding_revenue.nil?
  end

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

  def split_amount(total, shares)
    total = total.to_d
    amounts = shares.map { |share| (total * share).round(2) }
    amounts[-1] = total - amounts[0..-2].sum
    amounts
  end
end
