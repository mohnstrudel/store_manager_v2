# frozen_string_literal: true

class Colors::ShowResource < ApplicationResource
  typelize "Color"
  attribute :color do |page|
    ColorResource.new(page.fetch(:color)).serializable_hash
  end

  typelize "Array<ProductLink>"
  attribute :products do |page|
    ProductLinkResource.new(page.fetch(:color).products).serializable_hash
  end
end
