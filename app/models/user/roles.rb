# frozen_string_literal: true

module User::Roles
  extend ActiveSupport::Concern

  class_methods do
    def role_options_for_select
      roles.keys.map { (it == "admin") ? next : [it.humanize, it] }.compact
    end
  end
end
