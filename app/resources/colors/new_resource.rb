# frozen_string_literal: true

class Colors::NewResource < ApplicationResource
  typelize({value: :string})
  attribute :color do |page|
    color = page.fetch(:color)

    {value: color.value.to_s}
  end
end
