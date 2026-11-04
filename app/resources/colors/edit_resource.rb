# frozen_string_literal: true

class Colors::EditResource < ApplicationResource
  typelize "Color"
  attribute :color do |page|
    ColorResource.new(page.fetch(:color)).serializable_hash
  end
end
