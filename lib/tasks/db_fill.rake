namespace :db do
  desc "Fill our database with real data from Woo"
  task fill: :environment do
    puts "\n== Get products"
    products_variations = SyncWooProductsJob.perform_now
    puts "\n\n== Get products variations"
    SyncWooVariationsJob.perform_now(products_variations)
    puts "\n== Get sales"
    SyncWooOrdersJob.perform_now
    puts "\n\n== Get purchases"
    SyncPurchasesJob.perform_now
    puts "\n== All done!"
  end
end
