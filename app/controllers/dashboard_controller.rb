class DashboardController < ApplicationController
  def index
  end

  def debts
    @unpaid_purchases = Purchase.unpaid
    @sales_debt = ProductSale
      .includes(
        :sale,
        product: [:purchases, product_sales: :sale],
        variation: [:purchases, :version, :size, :color, product_sales: :sale]
      )
      .filter { |ps| Sale.has_wip_status? ps.status }
      .group_by(&:product_id)
      .sort_by { |_, product_sales_group|
        -product_sales_group.size
      }
      .first(16)
      .each { |_, product_sales_group|
        product_sales_group.uniq! { |ps| ps.item.id }
      }
      .flatten
      .filter { |el| !el.is_a? Integer }
  end
end
