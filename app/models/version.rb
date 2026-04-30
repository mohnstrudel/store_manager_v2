# frozen_string_literal: true

# == Schema Information
#
# Table name: versions
#
#  id         :bigint           not null, primary key
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Version < ApplicationRecord
  include HasAuditNotifications

  audited

  validates :value, presence: true

  has_many :product_versions, dependent: :destroy, inverse_of: :version
  has_many :products, through: :product_versions
  has_many :variants, dependent: :destroy, inverse_of: :version
end
