# frozen_string_literal: true

# == Schema Information
#
# Table name: sizes
#
#  id         :bigint           not null, primary key
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Size < ApplicationRecord
  include HasAuditNotifications
  include Size::Parsing

  audited

  validates :value, presence: true
  validates_db_uniqueness_of :value

  has_many :product_sizes, dependent: :destroy, inverse_of: :size
  has_many :products, through: :product_sizes
  has_many :variants, dependent: :destroy, inverse_of: :size
end
