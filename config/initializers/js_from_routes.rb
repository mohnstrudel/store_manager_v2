# frozen_string_literal: true

if defined?(JsFromRoutes)
  JsFromRoutes.config do |config|
    config.output_folder = Rails.root.join("app/frontend/api")
    config.helper_mappings = {"" => "list"}
  end
end
