# == Schema Information
#
# Table name: warehouses
#
#  id                        :bigint           not null, primary key
#  cbm                       :string
#  container_tracking_number :string
#  courier_tracking_url      :string
#  external_name             :string
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
  validates :external_name, presence: true

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
  # (none)
end
