# frozen_string_literal: true

module Product::SalesHistory
  extend ActiveSupport::Concern

  def fetch_active_sale_items
    sale_items
      .for_history
      .includes(purchase_items: :warehouse)
      .active
      .order(created_at: :asc)
  end

  def fetch_completed_sale_items
    sale_items.for_history.completed.order(created_at: :asc)
  end

  def sum_editions_sale_items
    SaleItem
      .active
      .where(edition: editions)
      .group(:edition_id)
      .sum(:qty)
  end

  def sum_editions_purchase_items
    Purchase
      .where(edition: editions)
      .group(:edition_id)
      .sum(:amount)
  end
end
