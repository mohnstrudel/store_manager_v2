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
#  shopify_id :string
#  woo_id     :string
#
class Customer < ApplicationRecord
  audited
  has_associated_audits

  include PgSearch::Model
  pg_search_scope :search,
    against: [:woo_id, :email, :first_name, :last_name, :phone],
    associated_against: {sales: :woo_id}

  paginates_per 50

  has_many :sales, dependent: :destroy

  before_save :downcase_email

  def name_and_email
    [full_name, email].compact.join(" — ")
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def title
    full_name
  end

  def self.woo_id_is_valid?(woo_id)
    !woo_id.in? [0, "0", ""]
  end

  def shopify_id_short
    shopify_id&.gsub("gid://shopify/Customer/", "")
  end

  def shop_id
    shopify_id_short || woo_id
  end

  private

  def downcase_email
    self.email = email&.downcase
  end
end
