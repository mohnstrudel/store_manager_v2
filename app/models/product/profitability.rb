# frozen_string_literal: true

# Product-level profitability aggregated over the sale items of active and
# completed sales: realized numbers use money already received from Shopify,
# expected numbers use the full expected sale amounts. Also exposes the
# warehouse-side inventory economics (units purchased, sold, and remaining,
# plus the cost frozen in unsold stock) that the product page's summary needs.
module Product::Profitability
  extend ActiveSupport::Concern

  def profitability_sale_items
    sale_items
      .joins(:sale)
      .where(sales: {status: Sale.active_status_names + Sale.completed_status_names})
      .includes(:sale, purchase_items: :purchase)
  end

  def profitability(expense_fraction: ExpenseRate.combined_fraction)
    items = profitability_sale_items.to_a
    linked_purchase_items = items.flat_map(&:purchase_items)

    expected_revenue = items.sum(0.to_d) { |item| item.expected_revenue.to_d }
    received_revenue = items.sum(0.to_d) { |item| item.received_revenue.to_d }
    item_cost_total = linked_purchase_items.sum(0.to_d) { |purchase_item| purchase_item.purchase.item_price.to_d }
    shipping_cost_total = linked_purchase_items.sum(0.to_d) { |purchase_item| purchase_item.shipping_cost.to_d }
    direct_expenses = linked_purchase_items.sum(0.to_d) { |purchase_item| purchase_item.expenses.to_d }
    purchase_cost = item_cost_total + shipping_cost_total + direct_expenses
    business_expenses = items.sum(0.to_d) { |item| item.business_expenses(expense_fraction) }
    expected_final_profit = expected_revenue - purchase_cost - business_expenses

    {
      expected_revenue:,
      received_revenue:,
      outstanding_revenue: items.sum(0.to_d, &:future_revenue),
      refunded_revenue: items.sum(0.to_d) { |item| item.refunded_revenue.to_d },
      purchase_cost:,
      direct_expenses:,
      # What the goods themselves cost, once the named direct expenses are
      # taken out of the cost of goods — mirrors Sale::Profitability so the
      # product and sale equations read alike and deduct the expenses once.
      merchandise_cost: purchase_cost - direct_expenses,
      business_expenses:,
      realized_profit: received_revenue - purchase_cost - business_expenses,
      expected_final_profit:,
      margin_percent: profitability_margin(expected_final_profit, expected_revenue),
      status: profitability_status_for(expected_final_profit, items),
      # Whether the product has any sale items this equation counts, decided
      # here once so the frontend visibility gate has a single source instead
      # of independently re-deriving it from a different status set.
      has_sale_items: items.present?,
      # How many orders these figures were added up from, so the page can say
      # what a total covers. Distinct sales, not sale items: one order can
      # carry several lines of the same product, and a reader counts orders.
      counted_sales_total: items.map(&:sale_id).uniq.size
    }
  end

  # Inventory counted in physical warehouse units: each PurchaseItem row is
  # one unit, and a unit is sold once linked to a sale item. Purchases never
  # moved to a warehouse have no PurchaseItem rows and are not counted; sales
  # not yet linked to purchase items do not count as sold.
  def inventory_economics
    purchased_units = inventory_purchase_items.count
    sold_units = inventory_purchase_items.where.not(sale_item_id: nil).count

    {
      purchased_units:,
      sold_units:,
      remaining_units: purchased_units - sold_units,
      invested_total:,
      remaining_inventory_cost:
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

  # Everything paid for units of this product, sold or not. Deliberately summed
  # over every purchased unit rather than as purchase_cost + remaining_inventory_cost:
  # purchase_cost covers only active and completed sales, so a unit linked to a
  # cancelled sale would fall through both halves.
  def invested_total
    landed_cost_of(inventory_purchase_items)
  end

  def remaining_inventory_cost
    landed_cost_of(inventory_purchase_items.where(sale_item_id: nil))
  end

  def landed_cost_of(purchase_items)
    purchase_items.includes(:purchase).sum(0.to_d) { |purchase_item|
      purchase_item.purchase.item_price.to_d + purchase_item.shipping_cost.to_d + purchase_item.expenses.to_d
    }
  end

  def profitability_margin(profit, revenue)
    return nil unless revenue.positive?

    (profit / revenue * 100).round(2)
  end

  def profitability_status_for(profit, items)
    return :unknown if items.present? && items.all? { |item| item.expected_revenue.nil? }

    if profit.positive?
      :profitable
    elsif profit.negative?
      :loss
    else
      :break_even
    end
  end
end
