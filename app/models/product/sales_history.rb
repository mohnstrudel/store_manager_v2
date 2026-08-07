# frozen_string_literal: true

module Product::SalesHistory
  extend ActiveSupport::Concern

  def active_sale_items
    sale_items.for_history.active.order(created_at: :asc)
  end

  def completed_sale_items
    sale_items.for_history.completed.order(created_at: :asc)
  end

  def variant_sales_sums
    SaleItem
      .active
      .non_installment
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

  def variant_purchase_cost_totals
    PurchaseItem
      .joins(:purchase)
      .where(purchases: {variant_id: variants.select(:id)})
      .includes(:purchase)
      .group_by { |purchase_item| purchase_item.purchase.variant_id }
      .transform_values { |purchase_items|
        {
          cost: purchase_items.sum(0.to_d) { |pi| pi.cost.to_d + pi.expenses.to_d },
          units: purchase_items.size
        }
      }
  end
end
