# == Schema Information
#
# Table name: warehouses
#
#  id                        :bigint           not null, primary key
#  cbm                       :string
#  container_tracking_number :string
#  courier_tracking_url      :string
#  desc_de                   :string
#  desc_en                   :string
#  external_name_de          :string
#  external_name_en          :string
#  is_default                :boolean          default(FALSE), not null
#  name                      :string
#  position                  :integer          default(1), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
class Warehouse < ApplicationRecord
  #
  # == Concerns
  #
  include HasAuditNotifications
  include HasPreviewImages

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited
  has_associated_audits
  positioned

  #
  # == Validations
  #
  validates :name, presence: true

  #
  # == Associations
  #
  has_many :purchase_items, dependent: :destroy
  has_many :purchases, through: :purchase_items

  #
  # == Scopes
  #
  # (none)

  #
  # == Class Methods
  #
  def self.ensure_only_one_default(id)
    Warehouse
      .where(is_default: true)
      .where.not(id:)
      .update_all(is_default: false)
  end

  #
  # == Domain Methods
  #
  #
  def average_payment_progress
    return 0 if purchases.empty?

    progresses = purchases.map(&:progress)
    (progresses.sum / progresses.size).round
  end

  def total_debt
    purchases.sum(&:debt).round
  end
end
