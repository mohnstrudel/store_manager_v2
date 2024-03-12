namespace :db do
  desc "Sync images from Woo to R2 and our DB"
  task sync_images: :environment do
    puts "\n== Started syncing images, it may take about an hour"
    AttachImagesToProductsJob.perform_later
  end
end
