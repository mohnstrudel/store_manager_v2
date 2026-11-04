# frozen_string_literal: true

Typelizer.configure do |config|
  config.output_dir = Rails.root.join("app/frontend/types/serializers")
  config.types_import_path = "@/types/serializers"
  config.prefer_double_quotes = true
  config.properties_sort_order = :none
end
