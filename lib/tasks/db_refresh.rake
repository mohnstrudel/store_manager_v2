namespace :db do
  desc "Prepare DB for development by re-creating and populating the database"
  task refresh: :environment do
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:fill"].invoke
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
