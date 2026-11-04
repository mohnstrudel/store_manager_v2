# frozen_string_literal: true

class Brands::ShowResource < ApplicationResource
  typelize "Brand"
  attribute :brand do |page|
    BrandResource.new(page.fetch(:brand)).serializable_hash
  end

  typelize "Array<ProductLink>"
  attribute :products do |page|
    ProductLinkResource.new(page.fetch(:brand).products).serializable_hash
  end
end
