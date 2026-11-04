# frozen_string_literal: true

class Purchases::IndexResource < ApplicationResource
  typelize "Array<PurchasesListing>"
  attribute :purchases do |page|
    Purchases::ListingResource.new(page.fetch(:purchases)).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:purchases))
  end

  typelize({q: :string})
  attribute :search do |page|
    {q: page.fetch(:query)}
  end

  typelize "Array<WarehouseOption>"
  attribute :warehouses do |page|
    WarehouseOptionResource.new(page.fetch(:warehouses)).serializable_hash
  end

  typelize :string
  attribute :move_path do |_page|
    move_path
  end
end
