# frozen_string_literal: true

module Illustrated
  extend ActiveSupport::Concern
  include Galleried

  included do
    has_many :media, -> { ordered }, as: :mediaable, dependent: :destroy, inverse_of: :mediaable, class_name: "Media"
  end
end
