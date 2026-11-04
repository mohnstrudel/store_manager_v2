# frozen_string_literal: true

class Franchises::ShowResource < ApplicationResource
  typelize "Franchise"
  attribute :franchise do |page|
    FranchiseResource.new(page.fetch(:franchise)).serializable_hash
  end

  typelize "Array<ProductLink>"
  attribute :products do |page|
    ProductLinkResource.new(page.fetch(:franchise).products).serializable_hash
  end
end
