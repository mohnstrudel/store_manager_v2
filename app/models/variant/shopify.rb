# frozen_string_literal: true

module Variant::Shopify
  OPTION_NAMES = {
    version: ["Version", "Edition", "Variant", "Variante", "Variants"],
    size: ["Size", "Scale"],
    color: ["Color"]
  }.freeze
  PLACEHOLDER_OPTION_NAME = "Title"
  private_constant :OPTION_NAMES, :PLACEHOLDER_OPTION_NAME

  def self.dimension_for(option_name)
    return if option_name == PLACEHOLDER_OPTION_NAME

    OPTION_NAMES.find { |_dimension, names| names.include?(option_name) }&.first || :version
  end
end
