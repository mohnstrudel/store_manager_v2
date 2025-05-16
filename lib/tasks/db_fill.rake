namespace :db do
  desc "Fill our database with real data from Shopify"
  task fill: :environment do
    puts "\n== Get products"
    Shopify::PullProductsJob.perform_later
    puts "\n== Everything is done!"
  end
end
