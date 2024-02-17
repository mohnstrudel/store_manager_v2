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
  Rake::Task["fill-db"].invoke
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
