# frozen_string_literal: true

class Sales::ListingResource < Sales::BaseResource
  typelize :string, nullable: true
  attribute :customer_name do |sale|
    sale.customer.full_name
  end

  typelize :string, nullable: true
  attribute :customer_email do |sale|
    sale.customer.email
  end

  many :sale_items, resource: Sales::ListingItemResource
end
