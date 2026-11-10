# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationsChannel do
  let(:user) { create(:user) }

  it "streams notifications for the connected user" do
    stub_connection(current_user: user)

    subscribe

    expect(subscription).to have_stream_for(user)
  end
end
