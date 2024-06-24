# == Schema Information
#
# Table name: customers
#
#  id         :bigint           not null, primary key
#  email      :string
#  first_name :string
#  last_name  :string
#  phone      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  woo_id     :string
#
class Customer < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :search,
    against: [:woo_id, :email, :first_name, :last_name, :phone],
    associated_against: {sales: :woo_id}

  paginates_per 50

  has_many :sales, dependent: :destroy

  before_save :downcase_email

  def name_and_email
    "#{first_name} #{last_name} — #{email}"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def downcase_email
    self.email = email&.downcase
  end
end
