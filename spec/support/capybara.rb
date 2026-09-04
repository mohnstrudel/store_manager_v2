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
    browser_options: {
      :"no-sandbox" => nil,
      "disable-smooth-scrolling" => true,
      :"window-size" => "1200,768"
    },
    process_timeout: 20,
    inspector: true,
    headless: !ENV["HEADLESS"].in?(%w[n 0 no false])
  )
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :better_cuprite

module CupriteHelpers
  def pause
    page.driver.pause
  end

  def debug(*)
    page.driver.debug(*)
  end
end

module BrowserStorageHelpers
  def clear_browser_storage
    return unless Capybara.current_session.driver.respond_to?(:browser)

    page.execute_script("window.sessionStorage.clear(); window.localStorage.clear();")
  rescue
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

  config.after(:each, :js, type: :feature) do
    clear_browser_storage
    Capybara.current_driver = Capybara.default_driver
  end
end
