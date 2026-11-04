# frozen_string_literal: true

class OutboundEmails::IndexResource < ApplicationResource
  typelize "Array<OutboundEmailsListing>"
  attribute :outbound_emails do |page|
    OutboundEmails::ListingResource.new(
      page.fetch(:outbound_emails),
      params: page.slice(:sale_items, :purchase_items, :customer_ids)
    ).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:outbound_emails))
  end

  typelize({q: :string})
  attribute :search do |page|
    {q: page.fetch(:query)}
  end
end
