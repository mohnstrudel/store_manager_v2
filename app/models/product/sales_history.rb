# frozen_string_literal: true

module Product::SalesHistory
  extend ActiveSupport::Concern

  def active_sale_items
    sale_items
      .for_history
      .includes(purchase_items: :warehouse)
      .active
      .order(created_at: :asc)
  end

  def completed_sale_items
    sale_items.for_history.completed.order(created_at: :asc)
  end

  def variant_sales_sums
    SaleItem
      .active
      .where(variant: variants)
      .group(:variant_id)
      .sum(:qty)
  end

  def variant_purchase_sums
    Purchase
      .where(variant: variants)
      .group(:variant_id)
      .sum(:amount)
  end
end
