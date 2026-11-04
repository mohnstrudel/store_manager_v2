# frozen_string_literal: true

class Sizes::NewResource < ApplicationResource
  typelize({value: :string})
  attribute :size do |page|
    size = page.fetch(:size)

    {value: size.value.to_s}
  end
end
