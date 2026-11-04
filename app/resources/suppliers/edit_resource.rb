# frozen_string_literal: true

class Suppliers::EditResource < ApplicationResource
  typelize "Supplier"
  attribute :supplier do |page|
    SupplierResource.new(page.fetch(:supplier)).serializable_hash
  end
end
