# frozen_string_literal: true

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module StoreManagerV2
  class Application < Rails::Application
    config.load_defaults 7.0
    jobs_concers_path = Rails.root.join("app/jobs/concerns")
    config.autoload_paths << jobs_concers_path
    config.eager_load_paths << jobs_concers_path

    services_path = Rails.root.join("app/services")
    config.autoload_paths << services_path
    config.eager_load_paths << services_path

    config.active_job.queue_adapter = :sidekiq

    config.action_mailer.preview_paths << Rails.root.join("app/mailers/previews").to_s

    config.generators do |generate|
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
