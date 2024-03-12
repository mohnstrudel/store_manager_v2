require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module StoreManagerV2
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    jobs_concers_path = Rails.root.join("app/jobs/concerns")
    config.autoload_paths << jobs_concers_path
    config.eager_load_paths << jobs_concers_path

    config.active_job.queue_adapter = :sidekiq

    config.generators do |generate|
      # generate.assets false
      generate.helper false
      generate.stylesheets false
      generate.controller_specs false
      generate.request_specs false
      generate.view_specs false
      generate.helper_specs false
      generate.routing_specs false
    end
  end
end
