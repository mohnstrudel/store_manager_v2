desc "Prepare our application for testing by re-creating and populating the database"
task refresh: :environment do
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
  Rake::Task["db:seed"].invoke
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
