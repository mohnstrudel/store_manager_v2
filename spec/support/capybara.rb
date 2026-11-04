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
    timeout: 15,
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

RSpec.configure do |config|
  config.include CupriteHelpers, type: :feature

  config.before(:suite) do
    if RSpec.world.example_groups.any? { |group| group.metadata[:type] == :feature }
      Rails.root.join("tmp/vite-test-build.lock").open(File::RDWR | File::CREAT) do |lock|
        lock.flock(File::LOCK_EX)
        ViteRuby.commands.build || abort("Vite test build failed")
      end
    end
  end
end
