class DashboardController < ApplicationController
  def index
  end

  def debts
    @unpaid_purchases = Purchase.unpaid
    @sales_debt = ActiveRecord::Base.connection.execute(sql_debts_query)
      .to_a.first(16).map(&:symbolize_keys)
  end

  private

  def sql_debts_query
    wip_statuses = Sale.wip_statuses.map { |str| "'#{str}'" }.join(", ")
    "
      SELECT
        product_sales.product_id,
        products.full_title,
        product_sales.variation_id,
        variations.title,
        COUNT(purchases.id) AS purchase_count,
        (
          SELECT COUNT(*)
          FROM product_sales ps
          JOIN sales s ON ps.sale_id = s.id
          WHERE ps.product_id = product_sales.product_id
            AND s.status IN (#{wip_statuses})
        ) AS total_sales_count,
        (
          SELECT COUNT(*)
          FROM product_sales ps
          JOIN sales s ON ps.sale_id = s.id
          WHERE ps.product_id = product_sales.product_id
            AND ps.variation_id IS NULL
            AND s.status IN (#{wip_statuses})
        ) AS products_sales_count,
        (
          SELECT COUNT(*)
          FROM product_sales ps
          JOIN sales s ON ps.sale_id = s.id
          WHERE ps.variation_id = product_sales.variation_id
            AND s.status IN (#{wip_statuses})
        ) AS variations_sales_count
      FROM product_sales
        JOIN sales ON product_sales.sale_id = sales.id
        JOIN products ON product_sales.product_id = products.id
        LEFT JOIN variations ON product_sales.variation_id = variations.id
        LEFT JOIN purchases ON (
          purchases.variation_id = product_sales.variation_id
        ) OR (
          purchases.product_id = product_sales.product_id
        )
      WHERE sales.status IN (#{wip_statuses})
      GROUP BY
        product_sales.product_id,
        products.full_title,
        product_sales.variation_id,
        variations.title
      ORDER BY total_sales_count DESC;
    "
  end
end
