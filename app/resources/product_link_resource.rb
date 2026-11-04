# frozen_string_literal: true

class ProductLinkResource < ApplicationResource
  typelize_from Product

  attributes :id, :full_title

  typelize :string
  attribute :path do |product|
    product_path(product)
  end
end
