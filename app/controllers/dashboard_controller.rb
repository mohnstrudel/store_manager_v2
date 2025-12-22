# frozen_string_literal: true
class DashboardController < ApplicationController
  def index
    @suppliers_debts = Supplier
      .includes(purchases: [:payments, :purchase_items])
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
    @config = Config
  end

  def debts
    @unpaid_purchases = Purchase.unpaid.includes(:supplier)
    @debts = if params[:q].present?
      search_query = params[:q].downcase
      sale_debts.select do |product|
        product.full_title&.downcase&.include?(search_query) ||
          product.editions.any? do |edition|
            edition.title&.downcase&.include?(search_query)
          end
      end
    else
      sale_debts
    end
    @debts = Kaminari.paginate_array(@debts).page(params[:page]).per(25)
  end

  def pull_last_orders
    SyncWooOrdersJob.perform_later(pages: 2)
    Config.enable_sales_hook

    respond_to do |format|
      format.html { redirect_to request.referer, notice: "Started getting missing sales. It'll take around 5–10 minutes" }
    end
  end

  def noop
  end

  private

  def sale_debts
    edition_debt_query = <<-SQL.squish
      SUM(COALESCE(sold.total_qty, 0)) - SUM(COALESCE(purchased_editions.amount, 0))
    SQL

    debt_query = <<-SQL.squish
      CASE
        WHEN sold.edition_id > 0 THEN #{edition_debt_query}
        ELSE
          SUM(COALESCE(sold.total_qty, 0)) - SUM(COALESCE(purchased.amount, 0))
      END
    SQL

    Product
      .select(<<-SQL.squish)
        products.*,
        SUM(sold.total_qty) AS sold_amount,
        SUM(purchased.amount) AS purchased_amount,
        SUM(purchased_editions.amount) AS purchased_editions_amount,
        #{debt_query} AS debt,
        #{edition_debt_query} AS editions_debt,
        sold.edition_id AS sale_edition_id,
        editions.edition_name AS edition_name
      SQL
      .joins(<<-SQL.squish)
        LEFT JOIN (#{sold.to_sql}) sold
          ON sold.product_id = products.id
        LEFT JOIN (#{purchased.to_sql}) purchased
          ON purchased.product_id = products.id
        LEFT JOIN (#{purchased_editions.to_sql}) purchased_editions
          ON purchased_editions.edition_id = sold.edition_id
        LEFT JOIN (#{editions.to_sql}) editions
          ON editions.edition_id = sold.edition_id
      SQL
      .group(<<-SQL.squish)
        products.id,
        products.full_title,
        sold.edition_id,
        editions.edition_name
      SQL
      .having("#{debt_query} > 0 AND #{edition_debt_query} > 0")
      .order(debt: :desc, editions_debt: :desc)
  end

  def sold
    SaleItem
      .select(<<-SQL.squish)
        product_id,
        edition_id,
        SUM(qty) AS total_qty
      SQL
      .joins(:sale)
      .where(sales: {status: Sale.active_status_names})
      .group("product_id, edition_id")
  end

  def purchased
    Purchase
      .select(<<-SQL.squish)
        product_id,
        edition_id,
        SUM(amount) AS amount
      SQL
      .where(edition_id: nil)
      .group("product_id, edition_id")
  end

  def purchased_editions
    Purchase
      .select(<<-SQL.squish)
        edition_id,
        SUM(amount) AS amount
      SQL
      .where.not(edition_id: nil)
      .group("edition_id")
  end

  def editions
    Edition
      .select(<<-SQL.squish)
        editions.id AS edition_id,
        COALESCE(versions.value, colors.value, sizes.value) AS edition_name
      SQL
      .joins(<<-SQL.squish)
        LEFT JOIN versions ON versions.id = editions.version_id
        LEFT JOIN colors ON colors.id = editions.version_id
        LEFT JOIN sizes ON sizes.id = editions.version_id
      SQL
      .group("editions.id, versions.value, colors.value, sizes.value")
  end
end
