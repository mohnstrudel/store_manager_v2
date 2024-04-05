require "capybara/rspec"
require "capybara/cuprite"

Capybara.default_max_wait_time = 3
Capybara.default_normalize_ws = true

Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1280, 1000],
    # See additional options for Dockerized environment in the respective section of this article
    browser_options: {},
    # Increase Chrome startup wait time (required for stable CI builds)
    process_timeout: 10,
    # Enable debugging capabilities
    inspector: true,
    # Allow running Chrome in a headful mode by setting HEADLESS env
    # var to a falsey value
    headless: !ENV["HEADLESS"].in?(%w[n 0 no false])
  )
end

Capybara.default_driver = Capybara.javascript_driver = :better_cuprite
