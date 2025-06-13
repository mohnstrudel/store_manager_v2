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
  audited
  has_associated_audits
  include HasAuditNotifications

  validates :title, presence: true
  has_many :products, dependent: :destroy

  after_save :update_products

  private

  def update_products
    products.each(&:update_full_title)
  end
end
