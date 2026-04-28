# frozen_string_literal: true

module Product::Shapes
  extend ActiveSupport::Concern

  DEFAULT_SHAPE = "Statue"
  OPTIONS = [
    DEFAULT_SHAPE,
    "Bust"
  ].freeze

  included do
    attribute :shape, :string, default: DEFAULT_SHAPE
    validates :shape, presence: true, inclusion: {in: OPTIONS}
  end

  class_methods do
    def shape_options
      OPTIONS
    end

    def default_shape
      DEFAULT_SHAPE
    end
  end
end
