# frozen_string_literal: true

class Products::IndexResource < ApplicationResource
  typelize "Array<ProductsListing>"
  attribute :products do |page|
    Products::ListingResource.new(page.fetch(:products)).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:products))
  end

  typelize({q: :string})
  attribute :search do |page|
    {q: page.fetch(:query).to_s}
  end

  typelize :string, nullable: true
  attribute :last_sync_at do |_page|
    format_last_fetched_at(Config.shopify_products_sync_at)
  end
end
