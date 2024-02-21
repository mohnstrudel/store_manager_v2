desc "Prepare our application for testing by re-creating and populating the database"
task refresh: :environment do
  # Clear cache and logs
  Rails.cache.clear
  Rake::Task["log:clear"].invoke
  # Remove stored files
  storage_path = Rails.root.join("storage/*")
  puts "Removing all files from #{storage_path}"
  FileUtils.rm_rf(Dir.glob(storage_path))
  puts "Storage directory has been cleared."
  # Refresh DB
  Rake::Task["db:drop"].invoke
  Rake::Task["db:create"].invoke
  Rake::Task["db:migrate"].invoke
  products_variations = SyncWooProductsJob.perform_now
  puts "SyncWooProductsJob is finished"
  SyncWooVariationsJob.perform_now(products_variations)
  puts "SyncWooVariationsJob is finished"
  SyncWooOrdersJob.perform_now
  puts "SyncWooOrdersJob is finished"
  SyncPurchasesJob.perform_now
  puts "SyncPurchasesJob is finished"
  AttachImagesToProductsJob.perform_later
  puts <<~'EOF'


           _,     _   _     ,_
       .-'` /     \'-'/     \ `'-.
      /    |      |   |      |    \
     ;      \_  _/     \_  _/      ;
    |         ``         ``         |
    |                               |
     ;    .-.   .-.   .-.   .-.    ;
      \  (   '.'   \ /   '.'   )  /
       '-.;         V         ;.-'
           `                 `

  EOF
end
