# frozen_string_literal: true

class Brands::NewResource < ApplicationResource
  typelize({title: :string})
  attribute :brand do |page|
    brand = page.fetch(:brand)

    {title: brand.title.to_s}
  end
end
