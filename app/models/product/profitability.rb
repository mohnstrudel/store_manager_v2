# frozen_string_literal: true

# Product-level economics driven by purchased inventory, not by what has
# sold: Potential sales prices every purchased unit at its variant's selling
# price, the expected total cost is everything spent landing those units,
# and OpEx is estimated on potential sales. Cash position nets money kept
# from customers against money actually paid to suppliers.
module Product::Profitability
  extend ActiveSupport::Concern

  def profitability_sale_items
    sale_items
      .joins(:sale)
      .where(sales: {status: Sale.active_status_names + Sale.completed_status_names})
  end

  def profitability(expense_fraction: ExpenseRate.combined_fraction)
    purchase_items = inventory_purchase_items.includes(purchase: :variant).to_a

    potential_sales = purchase_items.sum(0.to_d) { |purchase_item| purchase_item.purchase.variant&.selling_price.to_d }
    expected_total_cost = landed_cost_of(purchase_items)
    business_expenses = (potential_sales * expense_fraction).round(2)
    collected_revenue = profitability_sale_items.sum(0.to_d) { |item| item.received_revenue.to_d - item.refunded_revenue.to_d }
    purchase_paid = inventory_purchases.sum(:paid)

    {
      potential_sales:,
      expected_total_cost:,
      business_expenses:,
      expected_net_profit: potential_sales - expected_total_cost - business_expenses,
      collected_revenue:,
      purchase_paid:,
      cash_position: collected_revenue - purchase_paid
    }
  end

  private

  def inventory_purchases
    variant_purchases = Purchase.where(variant_id: variants.select(:id))
    product_purchases = Purchase.where(product_id: id, variant_id: nil)

    variant_purchases.or(product_purchases)
  end

  def inventory_purchase_items
    PurchaseItem.joins(:purchase).merge(inventory_purchases)
  end

  # Landed cost of a purchased unit: the purchase's own item price, plus this
  # unit's own shipping and direct expenses.
  def landed_cost_of(purchase_items)
    purchase_items.sum(0.to_d) { |purchase_item|
      purchase_item.purchase.item_price.to_d + purchase_item.shipping_cost.to_d + purchase_item.expenses.to_d
    }
  end
end
