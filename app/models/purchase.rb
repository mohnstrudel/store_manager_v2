# == Schema Information
#
# Table name: purchases
#
#  id              :bigint           not null, primary key
#  amount          :integer
#  order_reference :string
#  price           :decimal(8, 2)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_id      :bigint           not null
#  supplier_id     :bigint           not null
#
class Purchase < ApplicationRecord
  belongs_to :supplier
  belongs_to :product

  has_many :payments, dependent: :destroy

  delegate :full_title, to: :product

  def paid
    payments.pluck(:value).sum
  end

  def debt
    price - paid
  end

  def item_debt
    (price - paid) / amount
  end

  def progress
    paid / (price * BigDecimal("0.01"))
  end

  def item_price
    price / amount
  end
end
