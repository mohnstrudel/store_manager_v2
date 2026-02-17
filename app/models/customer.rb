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
  #
  # == Concerns
  #
  include HasAuditNotifications
  include Searchable
  include Shopable

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited
  has_associated_audits
  set_search_scope :search,
    against: [:woo_id, :email, :first_name, :last_name, :phone],
    associated_against: {sales: :woo_id}
  paginates_per 50

  #
  # == Associations
  #
  has_many :sales, dependent: :destroy

  #
  # == Callbacks
  #
  before_save :downcase_email

  #
  # == Class Methods
  #
  def self.woo_id_is_valid?(woo_id)
    !woo_id.in? [0, "0", ""]
  end

  #
  # == Domain Methods
  #
  def name_and_email
    parts = [full_name.strip, email].compact_blank
    parts.join(" — ")
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def title
    full_name
  end

  private

  def downcase_email
    self.email = email&.downcase
  end
end
