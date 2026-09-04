# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "4.0.6"

gem "rails", "~> 8.x.x"
gem "sprockets-rails"

gem "pg", "~> 1.6"
gem "puma", "~> 7.1.x"
gem "redis"
gem "bcrypt", "~> 3.1.x"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"
gem "pundit"
gem "sidekiq", "~> 8.0"
gem "sidekiq-status"
gem "pg_query", ">= 2"
gem "pg_search"
gem "audited"
gem "positioning"
gem "database_validations"
gem "acts-as-taggable-on"
gem "kaminari"
gem "friendly_id"
gem "slim-rails"
gem "vite_rails"
gem "inertia_rails"
gem "aws-sdk-s3", require: false
gem "shopify_app"
gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"
gem "down", "~> 5.0"
gem "httparty"

group :production do
  gem "mailtrap"
end

group :production, :staging do
  gem "rack-timeout"
end

group :production do
  gem "scout_apm"
end

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "faker", "~> 3.2"
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rspec-rails"
  gem "rubocop-rspec_rails", require: false
  gem "rubocop-factory_bot", require: false
  gem "factory_bot_rails"
  gem "parallel_tests"
  gem "dotenv"
  gem "js_from_routes", "~> 4.0"
end

group :development do
  gem "web-console"
  gem "rails_live_reload"
  gem "annotaterb"
  gem "solargraph"
  gem "solargraph-rails"
  gem "rubocop-slim"
  gem "pry"
  gem "pghero"
  gem "prosopite"
  gem "standard", require: false
  gem "letter_opener"
  gem "rails-mcp-server"
  gem "ruby-lsp"
end

group :test do
  gem "capybara"
  gem "cuprite"
  gem "duck_typer", "~> 0.6.1"
  gem "pundit-matchers"
  gem "shoulda-matchers"
  gem "rails-controller-testing"
  gem "vcr"
  gem "webmock"
end
