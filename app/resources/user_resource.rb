# frozen_string_literal: true

class UserResource < ApplicationResource
  typelize_from User

  attributes :id, :email_address

  typelize :string, nullable: true
  attribute :first_name do |user|
    user.first_name.presence
  end

  typelize :string, nullable: true
  attribute :last_name do |user|
    user.last_name.presence
  end

  typelize :string
  attribute :role do |user|
    user.role.humanize
  end

  typelize :string
  attribute :created_at do |user|
    format_date(user.created_at)
  end

  typelize :string
  attribute :updated_at do |user|
    format_date(user.updated_at)
  end

  typelize :string
  attribute :path do |user|
    user_path(user)
  end

  typelize :string
  attribute :edit_path do |user|
    edit_user_path(user)
  end

  typelize :string
  attribute :destroy_path do |user|
    user_path(user)
  end
end
