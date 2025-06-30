# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email_address   :string           not null
#  first_name      :string
#  last_name       :string
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates_db_uniqueness_of :email_address
  validates :email_address, format: {with: URI::MailTo::EMAIL_REGEXP}

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
