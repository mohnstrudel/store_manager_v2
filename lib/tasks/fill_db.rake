desc "Fill the database with real data from Woo"
task refresh: :environment do
  puts "\n== Get products"
  products_variations = SyncWooProductsJob.perform_now
  puts "\n== Get products variations"
  SyncWooVariationsJob.perform_now(products_variations)
  puts "\n== Get sales"
  SyncWooOrdersJob.perform_now
  puts "\n== Get purchases"
  SyncPurchasesJob.perform_now
end
