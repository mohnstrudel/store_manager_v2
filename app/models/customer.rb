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
  paginates_per 50

  has_many :sales, dependent: :destroy

  def name_and_email
    "#{first_name} #{last_name} — #{email}"
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
