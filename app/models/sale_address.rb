# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_addresses
#
#  id         :bigint           not null, primary key
#  address_1  :string
#  address_2  :string
#  city       :string
#  company    :string
#  country    :string
#  email      :string
#  first_name :string
#  kind       :integer          not null
#  last_name  :string
#  phone      :string
#  postcode   :string
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  sale_id    :bigint           not null
#
class SaleAddress < ApplicationRecord
  enum :kind, {
    shipping: 0,
    billing: 1
  }

  db_belongs_to :sale, inverse_of: :addresses

  validates :kind, presence: true
  validates_db_uniqueness_of :kind, scope: :sale_id
end
