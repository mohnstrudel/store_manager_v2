# frozen_string_literal: true

# == Schema Information
#
# Table name: franchises
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Franchise < ApplicationRecord
  include HasAuditNotifications
  include ProductTitling

  audited
  has_associated_audits
  validates :title, presence: true
  has_many :products, dependent: :destroy, inverse_of: :franchise
end
