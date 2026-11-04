# frozen_string_literal: true

class Customers::IndexResource < ApplicationResource
  typelize "Array<Customer>"
  attribute :customers do |page|
    CustomerResource.new(page.fetch(:customers)).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:customers))
  end

  typelize({q: :string})
  attribute :search do |page|
    {q: page.fetch(:query)}
  end
end
