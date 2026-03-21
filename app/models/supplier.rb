# frozen_string_literal: true

# == Schema Information
#
# Table name: suppliers
#
#  id         :bigint           not null, primary key
#  slug       :string
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Supplier < ApplicationRecord
  include HasAuditNotifications

  extend FriendlyId

  audited
  has_associated_audits
  friendly_id :title, use: :slugged

  validates :title, presence: true
  has_many :purchases, dependent: :destroy, inverse_of: :supplier

  scope :includes_dashboard_associations, -> {
    includes(purchases: [:payments, :purchase_items])
  }
end
