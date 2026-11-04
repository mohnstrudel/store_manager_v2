# frozen_string_literal: true

class ShippingCompanies::IndexResource < ApplicationResource
  typelize "Array<ShippingCompany>"
  attribute :shippingCompanies do |page|
    ShippingCompanyResource.new(page.fetch(:shipping_companies)).serializable_hash
  end
end
