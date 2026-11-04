# frozen_string_literal: true

class Suppliers::NewResource < ApplicationResource
  typelize({title: :string})
  attribute :supplier do |page|
    supplier = page.fetch(:supplier)

    {title: supplier.title.to_s}
  end
end
