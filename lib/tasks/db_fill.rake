namespace :db do
  desc "Fill our database with real data from Woo"
  task fill: :environment do
    puts "\n== Get products"
    products_variations = SyncWooProductsJob.perform_now
    puts "\n== Get products variations"
    SyncWooVariationsJob.perform_now(products_variations)
    puts "\n== Get sales"
    SyncWooOrdersJob.perform_now
    puts "\n== Get purchases"
    SyncPurchasesJob.perform_now
    puts "\n== Syncing images in the background, it may take about an hour"
    AttachImagesToProductsJob.perform_later
    puts "\n== Everything else is done!"
  end
end
