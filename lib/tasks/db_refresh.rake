namespace :db do
  desc "Prepare our application for testing by re-creating and populating the database"
  task refresh: :environment do
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:fill"].invoke
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
end
