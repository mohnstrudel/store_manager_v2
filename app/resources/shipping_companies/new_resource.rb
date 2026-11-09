# frozen_string_literal: true

class ShippingCompanies::NewResource < ApplicationResource
  typelize({name: :string, tracking_url: "string | null"})
  attribute :shippingCompany do |page|
    shipping_company = page.fetch(:shipping_company)

    {name: shipping_company.name.to_s, tracking_url: shipping_company.tracking_url.presence}
  end
end
