desc "Prepare our application for testing by re-creating and populating the database"
task refresh: :environment do
  Rake::Task["db:drop"].invoke
  Rake::Task["db:create"].invoke
  Rake::Task["db:migrate"].invoke
  SyncWooProductsJob.perform_now
  puts "SyncWooProductsJob is finished"
  SyncWooOrdersJob.perform_now
  puts "SyncWooOrdersJob is finished"
  Rake::Task["db:seed"].invoke
end
