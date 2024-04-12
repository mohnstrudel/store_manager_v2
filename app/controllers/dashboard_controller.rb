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
      search_query = params[:q].downcase
      sale_debts.select do |product|
        product.full_title&.downcase&.include?(search_query) ||
          product.variations.any? do |variation|
            variation.title&.downcase&.include?(search_query)
          end
      end
    else
      sale_debts
    end
    @debts = Kaminari.paginate_array(@debts).page(params[:page]).per(25)
  end

  private

  def sale_debts
    variation_debt_query = <<-SQL.squish
      SUM(COALESCE(sold.total_qty, 0)) - SUM(COALESCE(purchased_variations.amount, 0))
    SQL

    debt_query = <<-SQL.squish
      CASE
        WHEN sold.variation_id > 0 THEN #{variation_debt_query}
        ELSE
          SUM(COALESCE(sold.total_qty, 0)) - SUM(COALESCE(purchased.amount, 0))
      END
    SQL

    Product
      .select(<<-SQL.squish)
        products.*,
        SUM(sold.total_qty) AS sold_amount,
        SUM(purchased.amount) AS purchased_amount,
        SUM(purchased_variations.amount) AS purchased_variations_amount,
        #{debt_query} AS debt,
        #{variation_debt_query} AS variations_debt,
        sold.variation_id AS sale_variation_id,
        variations.variation_name AS variation_name
      SQL
      .joins(<<-SQL.squish)
        LEFT JOIN (#{sold.to_sql}) sold
          ON sold.product_id = products.id
        LEFT JOIN (#{purchased.to_sql}) purchased
          ON purchased.product_id = products.id
        LEFT JOIN (#{purchased_variations.to_sql}) purchased_variations
          ON purchased_variations.variation_id = sold.variation_id
        LEFT JOIN (#{variations.to_sql}) variations
          ON variations.variation_id = sold.variation_id
      SQL
      .group(<<-SQL.squish)
        products.id,
        products.full_title,
        sold.variation_id,
        variations.variation_name
      SQL
      .having("#{debt_query} > 0 AND #{variation_debt_query} > 0")
      .order(debt: :desc, variations_debt: :desc)
  end

  def sold
    ProductSale
      .select(<<-SQL.squish)
        product_id,
        variation_id,
        SUM(qty) AS total_qty
      SQL
      .joins(:sale)
      .where(sales: {status: Sale.active_status_names})
      .group("product_id, variation_id")
  end

  def purchased
    Purchase
      .select(<<-SQL.squish)
        product_id,
        variation_id,
        SUM(amount) AS amount
      SQL
      .where(variation_id: nil)
      .group("product_id, variation_id")
  end

  def purchased_variations
    Purchase
      .select(<<-SQL.squish)
        variation_id,
        SUM(amount) AS amount
      SQL
      .where.not(variation_id: nil)
      .group("variation_id")
  end

  def variations
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
