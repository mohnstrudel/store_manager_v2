class DashboardController < ApplicationController
  def index
    @suppliers_debts = Supplier
      .includes(purchases: :payments)
      .map { |supplier|
        {
          supplier:,
          total_size: supplier.purchases.size,
          total_cost: supplier.purchases.sum(&:total_cost),
          paid: supplier.purchases.sum(&:paid),
          total_debt: supplier.purchases.reduce(0) do |memo, purchase|
            memo + purchase.debt
          end
        }
      }
      .sort_by { |a| -a[:total_debt] }
    @total_suppliers_debt = @suppliers_debts.pluck(:total_debt).sum
    @sale_debts = sale_debts
  end

  def debts
    @unpaid_purchases = Purchase.unpaid
    @debts = if params[:q].present?
      sale_debts.select do |product|
        product.sale_title&.downcase&.include?(params[:q])
      end
    else
      sale_debts
    end
    @debts = Kaminari.paginate_array(@debts).page(params[:page]).per(25)
  end

  private

  def sale_debts
    Product
      .select(<<-SQL.squish)
        products.*,
        MAX(COALESCE(sold_subquery.total_qty, 0)) AS sold,
        MAX(COALESCE(purchased_subquery.total_amount, 0)) AS purchased,
        MAX(COALESCE(sold_subquery.total_qty, 0)) -
          MAX(COALESCE(purchased_subquery.total_amount, 0)) AS debt,
        sold_subquery.full_title AS sale_title,
        sold_subquery.variation_id AS sale_variation_id,
        variations_subquery.variation_name AS variation_name
      SQL
      .joins(<<-SQL.squish)
        LEFT JOIN (#{sold_subquery.to_sql}) sold_subquery
          ON sold_subquery.product_id = products.id
        LEFT JOIN (#{purchased_subquery.to_sql}) purchased_subquery
          ON purchased_subquery.product_id = products.id
        LEFT JOIN (#{variations_subquery.to_sql}) variations_subquery
          ON variations_subquery.variation_id = sold_subquery.variation_id
      SQL
      .group(<<-SQL.squish)
        products.id,
        sold_subquery.full_title,
        sold_subquery.variation_id,
        variations_subquery.variation_name
      SQL
      .order("debt DESC")
  end

  def sold_subquery
    ProductSale
      .select(<<-SQL.squish)
        product_id,
        variation_id,
        full_title,
        SUM(qty) AS total_qty
      SQL
      .joins(:sale)
      .where(sales: {status: Sale.active_status_names})
      .group("product_id, variation_id, full_title")
  end

  def purchased_subquery
    Purchase
      .select(<<-SQL.squish)
        product_id,
        SUM(amount) AS total_amount
      SQL
      .group("product_id")
  end

  def variations_subquery
    Variation
      .select(<<-SQL.squish)
        variations.id AS variation_id,
        COALESCE(versions.value, colors.value, sizes.value) AS variation_name
      SQL
      .joins(<<-SQL.squish)
        LEFT JOIN versions ON versions.id = variations.version_id
        LEFT JOIN colors ON colors.id = variations.version_id
        LEFT JOIN sizes ON sizes.id = variations.version_id
      SQL
      .group("variations.id, versions.value, colors.value, sizes.value")
  end
end
