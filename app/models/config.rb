# == Schema Information
#
# Table name: configs
#
#  id                    :bigint           not null, primary key
#  sales_hook_status     :integer          default("disabled")
#  shopify_products_sync :datetime
#  shopify_sales_sync    :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
class Config < ApplicationRecord
  #
  # == Concerns
  #
  include HasAuditNotifications

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited
  enum :sales_hook_status, {disabled: 0, active: 1}
  CONFIG = Config.first_or_create

  #
  # == Validations
  #
  # (none)

  #
  # == Associations
  #
  # (none)

  #
  # == Scopes
  #
  # (none)

  #
  # == Class Methods
  #
  def self.sales_hook_disabled?
    CONFIG.sales_hook_status == "disabled"
  end

  def self.enable_sales_hook
    CONFIG.update(sales_hook_status: :active)
  end

  def self.disable_sales_hook
    CONFIG.update(sales_hook_status: :disabled)
  end

  def self.update_shopify_products_sync_time
    CONFIG.update(shopify_products_sync: Time.current)
  end

  def self.shopify_products_sync_time
    CONFIG.shopify_products_sync&.localtime&.strftime("%d.%m at %H:%M")
  end

  def self.update_shopify_sales_sync_time
    CONFIG.update(shopify_sales_sync: Time.current)
  end

  def self.shopify_sales_sync_time
    CONFIG.shopify_sales_sync&.localtime&.strftime("%d.%m at %H:%M")
  end

  #
  # == Domain Methods
  #
  # (none)
end
