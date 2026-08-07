# frozen_string_literal: true

# == Schema Information
#
# Table name: expense_rates
#
#  id           :bigint           not null, primary key
#  name         :string           not null
#  rate_percent :decimal(5, 2)    not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class ExpenseRate < ApplicationRecord
  has_many :operational_expenses, dependent: :nullify
  validates :name, presence: true
  validates_db_uniqueness_of :name
  validates :rate_percent,
    presence: true,
    numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

  scope :ordered, -> { order(rate_percent: :desc, name: :asc) }

  # Combined rate as a fraction of revenue, e.g. 17.5% -> 0.175
  def self.combined_fraction
    sum(:rate_percent) / 100
  end
end
