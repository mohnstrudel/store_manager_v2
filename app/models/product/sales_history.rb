# frozen_string_literal: true

module Product::SalesHistory
  extend ActiveSupport::Concern

  def active_sale_items
    merchandise_sale_items(sale_items.for_history.active)
  end

  def completed_sale_items
    merchandise_sale_items(sale_items.for_history.completed)
  end

  def active_payment_items
    payment_sale_items(sale_items.for_history.active)
  end

  def completed_payment_items
    payment_sale_items(sale_items.for_history.completed)
  end

  def variant_sales_sums
    SaleItem
      .active
      .non_installment
      .where(variant: variants)
      .includes(sale: [:origin_payment_plans, {sale_payment_parts: :sale_payment_plan}])
      .reject { |sale_item| sale_item.sale.follow_up_payment? }
      .group_by(&:variant_id)
      .transform_values { |sale_items_for_variant| sale_items_for_variant.sum(&:qty) }
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

  private

  def merchandise_sale_items(scope)
    scope.order(created_at: :asc).reject { |sale_item| sale_item.sale.follow_up_payment? }
  end

  def payment_sale_items(scope)
    scope.order(created_at: :asc).select { |sale_item| sale_item.sale.follow_up_payment? }
  end
end
