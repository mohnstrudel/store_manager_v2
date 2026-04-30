# frozen_string_literal: true

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
  include HasAuditNotifications
  include Identity
  include Listing
  include Searchable
  include Shopable

  audited
  has_associated_audits

  set_search_scope :search,
    against: [:email, :first_name, :last_name, :phone],
    associated_against: {
      woo_info: [:store_id],
      sales: [:shopify_name]
    }
  paginates_per 50

  has_many :sales, dependent: :destroy, inverse_of: :customer

  normalizes :email, with: ->(email) { email&.downcase }

  def self.woo_id_is_valid?(woo_id)
    !woo_id.in? [0, "0", ""]
  end
end
