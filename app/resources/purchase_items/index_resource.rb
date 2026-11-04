# frozen_string_literal: true

class PurchaseItems::IndexResource < ApplicationResource
  typelize "Array<PurchaseItemsListing>"
  attribute :purchase_items do |page|
    PurchaseItems::ListingResource.new(page.fetch(:purchase_items)).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:purchase_items))
  end

  typelize({q: :string})
  attribute :search do |page|
    {q: page.fetch(:query)}
  end
end
