# frozen_string_literal: true

class ShippingCompanies::EditResource < ApplicationResource
  typelize "ShippingCompany"
  attribute :shippingCompany do |page|
    ShippingCompanyResource.new(page.fetch(:shipping_company)).serializable_hash
  end
end
