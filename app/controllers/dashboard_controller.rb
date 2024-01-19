class DashboardController < ApplicationController
  def index
  end

  def debts
    @unpaid_purchases = Purchase.unpaid
    @debts = Product
      .select("
        products.*,
        COALESCE(sold_subquery.total_qty, 0) AS sold,
        COALESCE(purchased_subquery.total_amount, 0) AS purchased,
        COALESCE(sold_subquery.total_qty, 0) -
          COALESCE(purchased_subquery.total_amount, 0) AS debt,
        purchased_subquery.full_title AS purchase_title,
        sold_subquery.full_title AS sale_title,
        sold_subquery.variation_id AS sale_variation_id,
        variations_subquery.variation_name AS variation_name
      ")
      .joins("
        INNER JOIN (#{sold_subquery.to_sql}) sold_subquery
          ON sold_subquery.product_id = products.id
        INNER JOIN (#{purchased_subquery.to_sql}) purchased_subquery
          ON purchased_subquery.product_id = products.id
        LEFT JOIN (#{variations_subquery.to_sql}) variations_subquery
          ON variations_subquery.variation_id = sold_subquery.variation_id
      ")
      .group("
        products.id,
        sold_subquery.total_qty,
        purchased_subquery.total_amount,
        purchased_subquery.full_title,
        sold_subquery.full_title,
        sold_subquery.variation_id,
        variations_subquery.variation_name
      ")
      .order("debt DESC")
      .first(16)
      .filter { |product| product.debt > 0 }
  end

  private

  def sold_subquery
    ProductSale
      .select("
        product_id,
        variation_id,
        full_title,
        SUM(qty) AS total_qty
      ")
      .joins(:sale)
      .where(sales: {status: Sale.wip_statuses})
      .group("product_id, variation_id, full_title")
  end

  def purchased_subquery
    Purchase
      .select("product_id, full_title, SUM(amount) AS total_amount")
      .group("product_id, full_title")
  end

  def variations_subquery
    Variation
      .select("
        variations.id AS variation_id,
        COALESCE(versions.value, colors.value, sizes.value) AS variation_name
      ")
      .joins("
        LEFT JOIN versions ON versions.id = variations.version_id
        LEFT JOIN colors ON colors.id = variations.version_id
        LEFT JOIN sizes ON sizes.id = variations.version_id
      ")
      .group("variations.id, versions.value, colors.value, sizes.value")
  end
end
