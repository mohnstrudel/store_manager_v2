# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::Roles do
  describe ".role_options_for_select" do
    it "returns non-admin roles as humanized select options" do
      expect(User.role_options_for_select).to eq(
        [
          ["Guest", "guest"],
          ["Manager", "manager"],
          ["Support", "support"]
        ]
      )
    end
  end
end
