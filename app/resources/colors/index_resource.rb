# frozen_string_literal: true

class Colors::IndexResource < ApplicationResource
  typelize "Array<Color>"
  attribute :colors do |page|
    ColorResource.new(page.fetch(:colors)).serializable_hash
  end
end
