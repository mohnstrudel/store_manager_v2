# frozen_string_literal: true

class AddShopifyCurrencyFieldsToSales < ActiveRecord::Migration[8.1]
  def change
    add_column :sales, :shop_currency, :string
    add_column :sales, :presentment_currency, :string
    add_column :sales, :usd_conversion_rate, :decimal, precision: 18, scale: 10
    add_column :sales, :exchange_rate_date, :date

    add_check_constraint :sales,
      "(shop_currency IS NULL AND presentment_currency IS NULL AND usd_conversion_rate IS NULL AND exchange_rate_date IS NULL) " \
      "OR (shop_currency IS NOT NULL AND presentment_currency IS NOT NULL AND usd_conversion_rate IS NOT NULL AND exchange_rate_date IS NOT NULL)",
      name: "sales_currency_fields_all_or_none"

    add_check_constraint :sales,
      "shop_currency IS NULL OR shop_currency ~ '^[A-Z]{3}$'",
      name: "sales_shop_currency_format"

    add_check_constraint :sales,
      "presentment_currency IS NULL OR presentment_currency ~ '^[A-Z]{3}$'",
      name: "sales_presentment_currency_format"

    add_check_constraint :sales,
      "usd_conversion_rate IS NULL OR usd_conversion_rate > 0",
      name: "sales_usd_conversion_rate_positive"
  end
end
