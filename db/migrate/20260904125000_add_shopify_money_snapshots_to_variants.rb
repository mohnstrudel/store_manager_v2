# frozen_string_literal: true

class AddShopifyMoneySnapshotsToVariants < ActiveRecord::Migration[8.1]
  def change
    change_table :variants, bulk: true do |table|
      table.decimal :selling_price_source_amount, precision: 10, scale: 2
      table.string :selling_price_source_currency
      table.decimal :selling_price_exchange_rate, precision: 18, scale: 10
      table.date :selling_price_exchange_rate_date
    end

    add_check_constraint :variants,
      "(selling_price_source_amount IS NULL AND selling_price_source_currency IS NULL AND selling_price_exchange_rate IS NULL AND selling_price_exchange_rate_date IS NULL) OR " \
      "(selling_price_source_amount IS NOT NULL AND selling_price_source_currency = 'EUR' AND selling_price_exchange_rate > 0 AND selling_price_exchange_rate_date IS NOT NULL)",
      name: "variants_selling_price_source_snapshot_all_or_none"
  end
end
