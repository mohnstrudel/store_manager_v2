# frozen_string_literal: true

# == Schema Information
#
# Table name: editions
#
#  id             :bigint           not null, primary key
#  deactivated_at :datetime
#  purchase_cost  :decimal(10, 2)   default(0.0), not null
#  selling_price  :decimal(10, 2)   default(0.0), not null
#  sku            :string
#  weight         :decimal(10, 2)   default(0.0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  color_id       :bigint
#  product_id     :bigint           not null
#  shopify_id     :string
#  size_id        :bigint
#  version_id     :bigint
#  woo_id         :string
#
class Edition < ApplicationRecord
  include HasAuditNotifications
  include Shopable
  include Options

  audited associated_with: :product

  belongs_to :size, optional: true, inverse_of: :editions
  belongs_to :version, optional: true, inverse_of: :editions
  belongs_to :color, optional: true, inverse_of: :editions
  db_belongs_to :product, inverse_of: :editions

  has_many :sale_items, dependent: :nullify, inverse_of: :edition
  has_many :purchases, dependent: :nullify, inverse_of: :edition

  scope :active, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }

  def deactivated?
    deactivated_at?
  end

  def has_sales_or_purchases?
    sale_items.exists? || purchases.exists?
  end

  # Price tracking has been removed from StoreInfo
  # This method returns 0.0 for backwards compatibility
  def price
    0.0
  end
end
