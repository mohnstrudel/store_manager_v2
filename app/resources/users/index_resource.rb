# frozen_string_literal: true

class Users::IndexResource < ApplicationResource
  typelize "Array<User>"
  attribute :users do |page|
    UserResource.new(page.fetch(:users)).serializable_hash
  end
end
