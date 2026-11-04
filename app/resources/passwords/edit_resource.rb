# frozen_string_literal: true

class Passwords::EditResource < ApplicationResource
  typelize :string
  attribute :token do |page|
    page.fetch(:token)
  end
end
