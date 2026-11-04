# frozen_string_literal: true

class Customers::NewResource < ApplicationResource
  typelize({first_name: "string | null", last_name: "string | null", email: "string | null", phone: "string | null"})
  attribute :customer do |page|
    page.fetch(:customer).slice(:first_name, :last_name, :email, :phone)
  end
end
