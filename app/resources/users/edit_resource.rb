# frozen_string_literal: true

class Users::EditResource < ApplicationResource
  typelize({
    id: :number,
    email_address: :string,
    first_name: "string | null",
    last_name: "string | null",
    role: '"guest" | "admin" | "manager" | "support"',
    path: :string
  })
  attribute :user do |page|
    user = page.fetch(:user)

    {
      id: user.id,
      email_address: user.email_address,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      path: user_path(user)
    }
  end

  typelize "Array<[string, string]>"
  attribute :role_options do |_page|
    User.role_options_for_select
  end

  typelize :boolean
  attribute :is_admin do |page|
    page.fetch(:user).admin?
  end
end
