# frozen_string_literal: true

# == Schema Information
#
# Table name: configs
#
#  id                    :bigint           not null, primary key
#  sales_hook_status     :integer          default(0)
#  shopify_products_sync :datetime
#  shopify_sales_sync    :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
class Config < ApplicationRecord
  include AuditNotifiable

  audited
  enum :sales_hook_status, {disabled: 0, active: 1}

  def self.sales_hook_disabled?
    current.sales_hook_status == "disabled"
  end

  def self.current
    first_or_create
  end

  def self.enable_sales_hook
    current.update(sales_hook_status: :active)
  end

  def self.disable_sales_hook
    current.update(sales_hook_status: :disabled)
  end

  def self.update_shopify_products_sync_time
    current.update(shopify_products_sync: Time.current)
  end

  def self.shopify_products_sync_time
    shopify_products_sync_at&.in_time_zone&.strftime("%d.%m at %H:%M")
  end

  def self.shopify_products_sync_at
    current.shopify_products_sync
  end

  def self.update_shopify_sales_sync_time
    current.update(shopify_sales_sync: Time.current)
  end

  def self.shopify_sales_sync_time
    shopify_sales_sync_at&.in_time_zone&.strftime("%d.%m at %H:%M")
  end

  def self.shopify_sales_sync_at
    current.shopify_sales_sync
  end
end
