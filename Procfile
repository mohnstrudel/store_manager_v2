web: TARGET_PORT=$PORT thrust bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -c 1
release: bundle exec rails db:migrate
