# frozen_string_literal: true

require "capybara/rspec"
require "capybara/cuprite"

Capybara.default_max_wait_time = 10
Capybara.default_normalize_ws = true
Capybara.disable_animation = true

Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 768],
    viewport_size: [1200, 5000],
    # See additional options for Dockerized environment in the respective section of this article
    browser_options: {
      :"no-sandbox" => nil,
      "disable-smooth-scrolling" => true,
      :"window-size" => "1200,768"
    },
    # Increase Chrome startup wait time (required for stable CI builds)
    process_timeout: 20,
    # Enable debugging capabilities
    inspector: true,
    # Allow running Chrome in a headful mode by setting HEADLESS env
    # var to a falsey value
    headless: !ENV["HEADLESS"].in?(%w[n 0 no false])
  )
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :better_cuprite

module CupriteHelpers
  # Drop #pause anywhere in a test to stop the execution.
  # Useful when you want to checkout the contents of a web page in the middle of a test
  # running in a headful mode.
  def pause
    page.driver.pause
  end

  # Drop #debug anywhere in a test to open a Chrome inspector and pause the execution
  def debug(*)
    page.driver.debug(*)
  end
end

module BrowserStorageHelpers
  def clear_browser_storage
    return unless Capybara.current_session.driver.respond_to?(:browser)

    page.execute_script("window.sessionStorage.clear(); window.localStorage.clear();")
  rescue StandardError
    # Storage cleanup is best-effort; some pages or drivers disallow access.
  end
end

RSpec.configure do |config|
  config.include CupriteHelpers, type: :feature
  config.include BrowserStorageHelpers, type: :feature

  config.before(:each, type: :feature) do
    clear_browser_storage
  end

  config.before(:each, :js, type: :feature) do
    Capybara.current_driver = :better_cuprite
    clear_browser_storage
  end

  # Keep non-JS feature specs on the faster rack-test driver.
  config.after(:each, :js, type: :feature) do
    clear_browser_storage
    Capybara.current_driver = Capybara.default_driver
  end
end
