# frozen_string_literal: true

class Customers::ShowResource < ApplicationResource
  typelize "CustomersDetail"
  attribute :customer do |page|
    Customers::DetailResource.new(page.fetch(:customer)).serializable_hash
  end

  typelize "Array<CustomersSale>"
  attribute :active_sales do |page|
    Customers::SaleResource.new(page.fetch(:active_sales)).serializable_hash
  end

  typelize "Array<CustomersSale>"
  attribute :completed_sales do |page|
    Customers::SaleResource.new(page.fetch(:completed_sales)).serializable_hash
  end
end
