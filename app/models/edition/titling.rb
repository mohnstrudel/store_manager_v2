# frozen_string_literal: true

module Edition::Titling
  extend ActiveSupport::Concern

  def title
    values = [size&.value, version&.value, color&.value].compact
    values.blank? ? "Base Model" : values.join(" | ")
  end
end
