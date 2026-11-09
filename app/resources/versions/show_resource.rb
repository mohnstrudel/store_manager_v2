# frozen_string_literal: true

class Versions::ShowResource < ApplicationResource
  typelize "Version"
  attribute :version do |page|
    VersionResource.new(page.fetch(:version)).serializable_hash
  end

  typelize "Array<Product>"
  attribute :products do |page|
    ProductResource.new(page.fetch(:version).products).serializable_hash
  end
end
