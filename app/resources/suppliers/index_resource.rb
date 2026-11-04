# frozen_string_literal: true

class Suppliers::IndexResource < ApplicationResource
  typelize "Array<Supplier>"
  attribute :suppliers do |page|
    SupplierResource.new(page.fetch(:suppliers)).serializable_hash
  end
end
