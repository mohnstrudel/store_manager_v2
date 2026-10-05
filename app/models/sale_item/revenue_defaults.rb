# frozen_string_literal: true

module SaleItem::RevenueDefaults
  extend ActiveSupport::Concern

  included do
    before_save :apply_manual_revenue_defaults, unless: :shopify_id?
  end

  def payment_split_unknown?
    expected_revenue.present? && received_revenue.nil? && outstanding_revenue.nil?
  end

  private

  def apply_manual_revenue_defaults
    sync_from_price(:expected_revenue)
    self.refunded_revenue = 0 if refunded_revenue.nil?
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
