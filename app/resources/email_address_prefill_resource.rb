# frozen_string_literal: true

class EmailAddressPrefillResource < ApplicationResource
  typelize :string, nullable: true
  attribute :email_address do |page|
    email_address = page.fetch(:email_address)
    email_address.presence if email_address.is_a?(String)
  end
end
