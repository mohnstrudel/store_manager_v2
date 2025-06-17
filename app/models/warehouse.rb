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
  audited
  has_associated_audits

  positioned

  include HasAuditNotifications
  include HasPreviewImages

  has_many :purchase_items, dependent: :destroy
  has_many :purchases, through: :purchase_items

  validates :name, presence: true
  validates :external_name, presence: true

  def self.ensure_only_one_default(id)
    Warehouse
      .where(is_default: true)
      .where.not(id:)
      .update_all(is_default: false)
  end
end
