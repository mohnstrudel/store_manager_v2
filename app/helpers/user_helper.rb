# frozen_string_literal: true

module UserHelper
  def user_props(user)
    {
      id: user.id,
      email_address: user.email_address,
      first_name: user.first_name.presence || "-",
      last_name: user.last_name.presence || "-",
      role: user.role.humanize,
      created_at: format_date(user.created_at),
      updated_at: format_date(user.updated_at),
      path: user_path(user),
      edit_path: edit_user_path(user),
      destroy_path: user_path(user)
    }
  end
end
