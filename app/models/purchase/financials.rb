# frozen_string_literal: true

module Purchase::Financials
  extend ActiveSupport::Concern

  def debt
    @debt ||= [cost_total - paid, 0].max
  end

  def item_debt
    debt / amount
  end

  def item_paid
    paid / amount
  end

  def progress
    return 0 if cost_total.zero?

    [paid * 100.0 / cost_total, 100].min
  end

  def cost_total
    item_price * amount + shipping_total
  end

  def date
    purchase_date || created_at
  end

  def unpaid?
    payments_count.zero?
  end
end
