# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Action Mailer environment configuration" do
  def environment_config(name)
    Rails.root.join("config/environments/#{name}.rb").read
  end

  it "only configures Mailtrap in production" do
    production_config = environment_config("production")
    gemfile = Rails.root.join("Gemfile").read

    expect(production_config).to include("config.action_mailer.delivery_method = :mailtrap")
    expect(gemfile).to match(/group :production do\s+gem "mailtrap"\s+end/m)

    %w[development staging test].each do |environment|
      expect(environment_config(environment)).not_to include("config.action_mailer.delivery_method = :mailtrap")
      expect(environment_config(environment)).not_to include("config.action_mailer.mailtrap_settings =")
    end
  end

  it "keeps local previews in development without Mailtrap" do
    development_config = environment_config("development")

    expect(development_config).to include("config.action_mailer.perform_deliveries = true")
    expect(development_config).to include("config.action_mailer.delivery_method = :letter_opener")
  end

  it "disables email deliveries in staging" do
    staging_config = environment_config("staging")

    expect(staging_config).to include("config.action_mailer.perform_deliveries = false")
    expect(staging_config).to include("config.action_mailer.delivery_method = :test")
  end
end
