# frozen_string_literal: true

class SharedPropsResource < ApplicationResource
  typelize :string, nullable: true
  attribute :breadcrumb do |shared|
    shared.fetch(:breadcrumb)
  end

  typelize :string
  attribute :environment do |_shared|
    Rails.env.to_s
  end

  typelize({user: "CurrentUser | null"})
  attribute :auth do |shared|
    user = shared.fetch(:user)
    {user: user && CurrentUserResource.new(user).serializable_hash}
  end

  typelize :string
  attribute :csrf_token do |shared|
    shared.fetch(:csrf_token)
  end
end
