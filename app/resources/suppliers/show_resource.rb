# frozen_string_literal: true

class Suppliers::ShowResource < ApplicationResource
  typelize "Array<SuppliersPurchase>"
  attribute :purchases do |page|
    Suppliers::PurchaseResource.new(page.fetch(:purchases)).serializable_hash
  end

  typelize "Supplier"
  attribute :supplier do |page|
    SupplierResource.new(page.fetch(:supplier)).serializable_hash
  end
end
