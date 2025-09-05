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
  #
  # == Concerns
  #
  include HasAuditNotifications

  #
  # == Extensions
  #
  # (none)

  #
  # == Configuration
  #
  audited

  #
  # == Validations
  #
  validates :value, presence: true, uniqueness: true

  #
  # == Associations
  #
  has_many :product_sizes, dependent: :destroy
  has_many :products, through: :product_sizes
  has_many :editions, dependent: :destroy

  #
  # == Scopes
  #
  # (none)

  #
  # == Class Methods
  #
  def self.parse_size(product_title)
    num_sizes = product_title.scan(numeric_size_match).flatten

    return if num_sizes.blank?

    sizes = num_sizes.map { |size| size.tr("/", ":") }
    (sizes.length > 1) ? sizes : sizes.first
  end

  def self.sanitize_size(product_title)
    num_size = product_title.match(numeric_size_match)
    converted_title = num_size[0].tr("/", ":") if num_size.present?

    if converted_title
      product_title.sub(num_size[0], converted_title)
    else
      product_title
    end
  end

  def self.numeric_size_match
    # 1:2, 1:3, 1:4, 1:5, 1:6, 1:3.5, 1:1, 1:7, 1:10
    # and 1/2, 1/3, etc.
    /(1[\/:](?:[23456789]|3\.5|1[0]?))/
  end

  #
  # == Domain Methods
  #
  # (none)
end
