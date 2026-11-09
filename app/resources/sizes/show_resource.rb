# frozen_string_literal: true

class Sizes::ShowResource < ApplicationResource
  typelize "Size"
  attribute :size do |page|
    SizeResource.new(page.fetch(:size)).serializable_hash
  end

  typelize "Array<ProductLink>"
  attribute :products do |page|
    ProductLinkResource.new(page.fetch(:size).products).serializable_hash
  end
end
