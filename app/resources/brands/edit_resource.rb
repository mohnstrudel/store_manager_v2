# frozen_string_literal: true

class Brands::EditResource < ApplicationResource
  typelize "Brand"
  attribute :brand do |page|
    BrandResource.new(page.fetch(:brand)).serializable_hash
  end
end
