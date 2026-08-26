# frozen_string_literal: true

desc "One-time backfill: convert existing Shopify and WooCommerce sale money to USD and backfill settlement_status. Back up the database first; requires SHOPIFY_HISTORICAL_CURRENCY (the shop's verified historical base currency)."
task backfill_sales_to_usd: :environment do
  result = Sale::UsdBackfill.call(shopify_currency: ENV.fetch("SHOPIFY_HISTORICAL_CURRENCY"))

  puts "Converted #{result.converted_sale_ids.size} sale(s)."

  if result.unresolved_sale_ids.any?
    puts "Unresolved (missing external date), left null: #{result.unresolved_sale_ids.join(", ")}"
  end

  if result.failed_sale_ids.any?
    puts "Failed to convert #{result.failed_sale_ids.size} sale(s), left null for retry: #{result.failed_sale_ids.join(", ")}"
  end
end
