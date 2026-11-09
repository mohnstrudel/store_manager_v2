# frozen_string_literal: true

class SaleAddressResource < ApplicationResource
  typelize_from SaleAddress

  attributes :address_1, :address_2, :city, :company, :country, :email,
    :first_name, :last_name, :phone, :postcode, :state
end
