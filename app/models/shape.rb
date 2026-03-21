# frozen_string_literal: true

# == Schema Information
#
# Table name: shapes
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Shape < ApplicationRecord
  include HasAuditNotifications

  audited

  validates :title, presence: true

  has_many :products, dependent: :destroy, inverse_of: :shape
end
