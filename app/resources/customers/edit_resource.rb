# frozen_string_literal: true

class Customers::EditResource < ApplicationResource
  typelize "Customer"
  attribute :customer do |page|
    CustomerResource.new(page.fetch(:customer)).serializable_hash
  end
end
