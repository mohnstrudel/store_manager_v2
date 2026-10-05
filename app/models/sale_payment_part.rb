# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_payment_parts
#
#  id                    :bigint           not null, primary key
#  active                :boolean          default(TRUE), not null
#  amount                :decimal(12, 2)
#  currency              :string
#  due_at                :datetime
#  provider_completed_at :datetime
#  sequence              :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  external_order_id     :string
#  provider_part_id      :string
#  sale_id               :bigint
#  sale_payment_plan_id  :bigint           not null
#
class SalePaymentPart < ApplicationRecord
  belongs_to :sale_payment_plan, inverse_of: :parts
  belongs_to :sale, optional: true, inverse_of: :sale_payment_parts

  validates :sequence, numericality: {only_integer: true, greater_than: 0}
  validates_db_uniqueness_of :sequence, scope: :sale_payment_plan_id
  validates :provider_part_id,
    uniqueness: {scope: :sale_payment_plan_id},
    if: -> { provider_part_id.present? }

  scope :active, -> { where(active: true) }
end
