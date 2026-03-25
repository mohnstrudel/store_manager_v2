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

  def edition_sales_sums
    SaleItem
      .active
      .where(edition: editions)
      .group(:edition_id)
      .sum(:qty)
  end

  def edition_purchase_sums
    Purchase
      .where(edition: editions)
      .group(:edition_id)
      .sum(:amount)
  end
end
