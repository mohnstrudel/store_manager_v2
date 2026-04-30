# frozen_string_literal: true

module Variant::Options
  extend ActiveSupport::Concern

  class_methods do
    def types
      # Values should follow this rule: [English, German]
      {
        version: ["Version", "Variante"],
        size: ["Size", "Maßstab"],
        color: ["Color", "Farbe"],
        brand: ["Brand", "Marke"]
      }.freeze
    end
  end

  def base_model?
    size_id.nil? && version_id.nil? && color_id.nil?
  end

  def types_name
    types.join(" | ")
  end

  def types
    [size, version, color]
      .map { |item| item.presence && item.model_name.name }
      .compact
  end

  def types_size
    [size.presence, version.presence, color.presence].compact.size
  end

  def type_name_and_value
    [size, version, color].compact.map { |item| "#{item.model_name.name}: #{item.value}" }.join(", ")
  end
end
