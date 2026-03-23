# frozen_string_literal: true

module PurchaseItem::Financials
  extend ActiveSupport::Concern

  def cost
    purchase.item_price.to_f + shipping_cost.to_f
  end
end
