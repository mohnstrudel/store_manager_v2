# frozen_string_literal: true

module DashboardDebtReporting
  extend ActiveSupport::Concern

  private

  def sale_debts
    variant_debt_query = <<~SQL.squish
      SUM(COALESCE(sold.total_qty, 0)) - SUM(COALESCE(purchased_variants.amount, 0))
    SQL

    debt_query = <<~SQL.squish
      CASE
        WHEN sold.variant_id > 0 THEN #{variant_debt_query}
        ELSE
          SUM(COALESCE(sold.total_qty, 0)) - SUM(COALESCE(purchased.amount, 0))
      END
    SQL

    Product
      .select(<<~SQL.squish)
        products.*,
        SUM(sold.total_qty) AS sold_amount,
        SUM(purchased.amount) AS purchased_amount,
        SUM(purchased_variants.amount) AS purchased_variants_amount,
        #{debt_query} AS debt,
        #{variant_debt_query} AS variants_debt,
        sold.variant_id AS sale_variant_id,
        variants.variant_name AS variant_name
      SQL
      .joins(<<~SQL.squish)
        LEFT JOIN (#{sold.to_sql}) sold
          ON sold.product_id = products.id
        LEFT JOIN (#{purchased.to_sql}) purchased
          ON purchased.product_id = products.id
        LEFT JOIN (#{purchased_variants.to_sql}) purchased_variants
          ON purchased_variants.variant_id = sold.variant_id
        LEFT JOIN (#{variants.to_sql}) variants
          ON variants.variant_id = sold.variant_id
      SQL
      .group(<<~SQL.squish)
        products.id,
        products.full_title,
        sold.variant_id,
        variants.variant_name
      SQL
      .having("#{debt_query} > 0 AND #{variant_debt_query} > 0")
      .order(debt: :desc, variants_debt: :desc)
  end

  def sold
    SaleItem
      .select(<<~SQL.squish)
        product_id,
        variant_id,
        SUM(qty) AS total_qty
      SQL
      .joins(:sale)
      .where(sales: {status: Sale.active_status_names})
      .group("product_id, variant_id")
  end

  def purchased
    Purchase
      .select(<<~SQL.squish)
        product_id,
        variant_id,
        SUM(amount) AS amount
      SQL
      .where(variant_id: nil)
      .group("product_id, variant_id")
  end

  def purchased_variants
    Purchase
      .select(<<~SQL.squish)
        variant_id,
        SUM(amount) AS amount
      SQL
      .where.not(variant_id: nil)
      .group("variant_id")
  end

  def variants
    Variant
      .select(<<~SQL.squish)
        variants.id AS variant_id,
        COALESCE(versions.value, colors.value, sizes.value) AS variant_name
      SQL
      .joins(<<~SQL.squish)
        LEFT JOIN versions ON versions.id = variants.version_id
        LEFT JOIN colors ON colors.id = variants.color_id
        LEFT JOIN sizes ON sizes.id = variants.size_id
      SQL
      .group("variants.id, versions.value, colors.value, sizes.value")
  end
end
