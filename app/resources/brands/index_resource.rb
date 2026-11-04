# frozen_string_literal: true

class Brands::IndexResource < ApplicationResource
  typelize "Array<Brand>"
  attribute :brands do |page|
    BrandResource.new(page.fetch(:brands)).serializable_hash
  end
end
