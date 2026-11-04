# frozen_string_literal: true

class Sales::FormAddressResource < ApplicationResource
  typelize_from SaleAddress

  attributes(*Sale::Addressable::ADDRESS_ATTRIBUTES)
end
