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
  #
  # == Concerns
  #
  include HasAuditNotifications
  include Shopable

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited associated_with: :product

  #
  # == Associations
  #
  belongs_to :size, optional: true, inverse_of: :editions
  belongs_to :version, optional: true, inverse_of: :editions
  belongs_to :color, optional: true, inverse_of: :editions
  db_belongs_to :product, inverse_of: :editions

  has_many :sale_items, dependent: :nullify, inverse_of: :edition
  has_many :purchases, dependent: :nullify, inverse_of: :edition

  #
  # == Scopes
  #
  scope :active, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }
  scope :with_details, -> { includes(:version, :color, :size) }

  #
  # == Class Methods
  #
  def self.types
    # Values should follow this rule: [English, German]
    {
      version: ["Version", "Variante"],
      size: ["Size", "Maßstab"],
      color: ["Color", "Farbe"],
      brand: ["Brand", "Marke"]
    }.freeze
  end

  #
  # == Domain Methods
  #
  def title
    values = [size&.value, version&.value, color&.value].compact
    values.blank? ? "Base Model" : values.join(" | ")
  end

  def base_model?
    size_id.nil? && version_id.nil? && color_id.nil?
  end

  def deactivated?
    deactivated_at?
  end

  def has_sales_or_purchases?
    sale_items.exists? || purchases.exists?
  end

  def types_name
    types.join(" | ")
  end

  def types
    [size, version, color]
      .map { |i| i.presence && i.model_name.name }
      .compact
  end

  def types_size
    [size.presence, version.presence, color.presence].compact.size
  end

  def type_name_and_value
    [size, version, color].compact.map { |i| "#{i.model_name.name}: #{i.value}" }.join(", ")
  end

  # Price tracking has been removed from StoreInfo
  # This method returns 0.0 for backwards compatibility
  def price
    0.0
  end
end
