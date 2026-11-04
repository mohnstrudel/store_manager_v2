# frozen_string_literal: true

class ShippingCompanyOptionResource < ApplicationResource
  typelize_from ShippingCompany

  attributes :id, :name
end
