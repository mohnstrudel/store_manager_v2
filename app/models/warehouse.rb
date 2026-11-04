# frozen_string_literal: true

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
#  external_name             :string
#  external_name_de          :string
#  external_name_en          :string
#  is_default                :boolean          default(FALSE), not null
#  name                      :string
#  position                  :integer          default(1), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
class Warehouse < ApplicationRecord
  include Revisable
  include AuditNotifiable
  include Illustrated
  include Financials
  include Lifecycle
  include Transitions

  audited
  has_associated_audits
  positioned

  validates :name, presence: true

  has_many :purchase_items, dependent: :destroy, inverse_of: :warehouse
  has_many :purchases, through: :purchase_items

  scope :for_listing, -> {
    includes(:purchase_items, purchases: [:payments, :purchase_items])
  }

  scope :for_details, -> {
    includes(purchases: [:payments, :purchase_items], media: {image_attachment: :blob})
  }
end
