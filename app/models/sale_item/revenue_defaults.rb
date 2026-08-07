# frozen_string_literal: true

# Safe revenue fallbacks for sale items with no Shopify data (manual sale
# items and Woo imports): expected/received revenue track price unless the
# caller explicitly assigned them (e.g. Woo's importer computes its own
# expected_revenue), and outstanding/refunded revenue default to zero — unless
# the order itself cannot state its payment split, in which case the item stays
# as silent about payment as the order does.
# Shopify-imported items are left untouched here since Sale::RevenueAllocation
# owns their values.
module SaleItem::RevenueDefaults
  extend ActiveSupport::Concern

  included do
    before_save :apply_manual_revenue_defaults, unless: :shopify_id?
  end

  # Mirrors Sale#payment_split_unknown? one level down: an item is as silent
  # about its payment as the order it belongs to.
  def payment_split_unknown?
    expected_revenue.present? && received_revenue.nil? && outstanding_revenue.nil?
  end

  private

  def apply_manual_revenue_defaults
    sync_from_price(:expected_revenue)
    self.refunded_revenue = 0 if refunded_revenue.nil?
    # Mirroring the line price into received revenue would re-assert, per item,
    # the very split the importer refused to invent for the order.
    return if sale&.payment_split_unknown?

    sync_from_price(:received_revenue)
    self.outstanding_revenue = 0 if outstanding_revenue.nil?
  end

  def sync_from_price(attribute)
    return if will_save_change_to_attribute?(attribute)
    return unless public_send(attribute).nil? || price_changed?

    public_send("#{attribute}=", price)
  end
end
