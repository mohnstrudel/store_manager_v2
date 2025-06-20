source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.4"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.x.x"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use Redis adapter to run Action Cable in production
gem "redis"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

gem "slim-rails"
gem "httparty"
gem "kaminari"
gem "database_validations"
gem "pg_search"
gem "aws-sdk-s3", require: false
gem "ruby-progressbar"
gem "sidekiq", "~> 7.2"
gem "sidekiq-status"

# Add to postgresql.conf this two lines:
# shared_preload_libraries = 'pg_stat_statements'
# pg_stat_statements.track = all
gem "pg_query", ">= 2"

gem "requestjs-rails"
gem "friendly_id"

gem "inline_svg"
gem "mailtrap"

gem "shopify_app"

gem "audited"
gem "positioning"

gem "strong_migrations"

gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"

group :production, :staging do
  gem "thruster"
  gem "barnes"
  # Prevents webserver from spending time working on a request
  # that has been in-flight for longer than 30 seconds
  gem "rack-timeout"
end

group :production do
  gem "scout_apm"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "faker", "~> 3.2"
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rspec-rails", "~> 7.x.x"
  gem "factory_bot_rails"
  gem "dotenv"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
  gem "rails_live_reload"
  gem "annotaterb"
  gem "solargraph"
  gem "solargraph-rails"
  gem "rubocop-slim", "~> 0.2.2"
  gem "pry", "~> 0.14.2"
  # A performance dashboard for Postgres,
  # access at /pghero
  gem "pghero"
  # Prosopite is able to auto-detect Rails N+1 queries
  gem "prosopite"
  # Ruby Style Guide, with linter & automatic code fixer
  gem "standard", require: false
  gem "rubycritic", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "cuprite"
end
