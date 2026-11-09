# frozen_string_literal: true

class Users::ShowResource < ApplicationResource
  typelize "User"
  attribute :user do |page|
    UserResource.new(page.fetch(:user)).serializable_hash
  end
end
