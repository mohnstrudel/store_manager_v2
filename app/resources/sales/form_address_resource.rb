# frozen_string_literal: true

class Sales::FormAddressResource < ApplicationResource
  typelize_from SaleAddress

  attributes(*Sale::Addresses::ADDRESS_ATTRIBUTES)
end
