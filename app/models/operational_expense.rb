# frozen_string_literal: true

# == Schema Information
#
# Table name: operational_expenses
#
#  id              :bigint           not null, primary key
#  amount          :decimal(10, 2)   not null
#  category        :string           not null
#  incurred_on     :date             not null
#  note            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  expense_rate_id :bigint
#
class OperationalExpense < ApplicationRecord
  belongs_to :expense_rate, optional: true

  validates :incurred_on, :category, :amount, presence: true
  validates :amount, numericality: true

  scope :recent_first, -> { order(incurred_on: :desc, id: :desc) }
  scope :in_month, ->(month) { where(incurred_on: month.to_date.all_month) }
end
