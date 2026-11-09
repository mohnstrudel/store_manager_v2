# frozen_string_literal: true

class CurrentUserResource < ApplicationResource
  typelize_from User

  attributes :id, :email_address, :role
end
